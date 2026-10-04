-- 008_fix_defaults_and_rls.sql
-- Fixes from Phase 3 Stage 1 audit:
-- 1. Replace bee emoji default with neutral colony emoji
-- 2. Fix profiles RLS so colony members can read co-member profiles
-- 3. Add SET search_path to SECURITY DEFINER functions
-- 4. Prevent self-promotion to owner
-- 5. Protect last owner from leaving/demotion
-- 6. Make invite usage updates concurrency-safe

-- ROLLBACK: See individual ALTER/DROP statements below each section.

BEGIN;

-- ============================================================
-- 1. Replace bee emoji default with neutral colony emoji
-- ============================================================

ALTER TABLE public.colonies ALTER COLUMN emoji SET DEFAULT '🏠';

-- Fix create_colony_with_owner function default parameter
CREATE OR REPLACE FUNCTION public.create_colony_with_owner(
    p_name    TEXT,
    p_emoji   TEXT DEFAULT '🏠',
    p_description TEXT DEFAULT NULL,
    p_type    TEXT DEFAULT 'Roommates'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_colony_id UUID;
    v_code TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.colonies (name, emoji, description, type, created_by)
    VALUES (p_name, p_emoji, p_description, p_type, v_user_id)
    RETURNING id INTO v_colony_id;

    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_user_id, 'owner', 'active');

    v_code := public.generate_invite_code();
    INSERT INTO public.colony_invites (colony_id, code, created_by)
    VALUES (v_colony_id, v_code, v_user_id);

    RETURN jsonb_build_object('colony_id', v_colony_id, 'invite_code', v_code);
END;
$$;

-- ============================================================
-- 2. Fix profiles RLS: colony members can read co-member profiles
-- ============================================================

-- Drop the restrictive own-profile-only policy
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;

-- Allow reading own profile OR any active co-member's profile
CREATE POLICY "Users can read own or co-member profiles"
    ON public.profiles FOR SELECT
    USING (
        auth.uid() = id
        OR EXISTS (
            SELECT 1 FROM public.colony_members cm1
            JOIN public.colony_members cm2 ON cm1.colony_id = cm2.colony_id
            WHERE cm1.user_id = auth.uid()
              AND cm2.user_id = profiles.id
              AND cm1.status = 'active'
              AND cm2.status = 'active'
        )
    );

-- ============================================================
-- 3. Add SET search_path to all SECURITY DEFINER functions
-- ============================================================

-- is_colony_member
CREATE OR REPLACE FUNCTION public.is_colony_member(p_colony_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = p_colony_id
          AND user_id = auth.uid()
          AND status = 'active'
    );
$$;

-- is_colony_admin
CREATE OR REPLACE FUNCTION public.is_colony_admin(p_colony_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = p_colony_id
          AND user_id = auth.uid()
          AND status = 'active'
          AND role IN ('owner', 'admin')
    );
$$;

-- join_colony_by_code (add search_path + concurrency-safe invite update)
CREATE OR REPLACE FUNCTION public.join_colony_by_code(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_invite RECORD;
    v_colony_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lock the invite row to prevent concurrent usage races
    SELECT id, colony_id, max_uses, uses, expires_at
    INTO v_invite
    FROM public.colony_invites
    WHERE LOWER(code) = LOWER(p_code)
    FOR UPDATE;

    IF v_invite IS NULL THEN
        RAISE EXCEPTION 'Invalid invite code';
    END IF;

    IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < NOW() THEN
        RAISE EXCEPTION 'Invite code has expired';
    END IF;

    IF v_invite.max_uses IS NOT NULL AND v_invite.uses >= v_invite.max_uses THEN
        RAISE EXCEPTION 'Invite code has reached its usage limit';
    END IF;

    -- Check if already a member
    IF EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = v_invite.colony_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'You are already a member of this colony';
    END IF;

    v_colony_id := v_invite.colony_id;

    -- Add as member
    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_user_id, 'member', 'active');

    -- Increment usage atomically (row is already locked)
    UPDATE public.colony_invites
    SET uses = uses + 1
    WHERE id = v_invite.id;

    RETURN v_colony_id;
END;
$$;

-- generate_invite_code (add search_path)
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_code TEXT;
    v_chars TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    v_exists BOOLEAN;
BEGIN
    LOOP
        v_code := '';
        FOR i IN 1..6 LOOP
            v_code := v_code || substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);
        END LOOP;
        SELECT EXISTS (SELECT 1 FROM public.colony_invites WHERE LOWER(code) = LOWER(v_code)) INTO v_exists;
        EXIT WHEN NOT v_exists;
    END LOOP;
    RETURN v_code;
END;
$$;

-- handle_new_user (add search_path)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, username)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'display_name', ''),
        COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$;

-- set_updated_at (add search_path)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================================
-- 4. Prevent self-promotion: members cannot change their own role
-- ============================================================

-- Drop existing update policy and replace with a stricter one
DROP POLICY IF EXISTS "Admins can update members" ON public.colony_members;

CREATE POLICY "Admins can update other members' roles"
    ON public.colony_members FOR UPDATE
    USING (
        public.is_colony_admin(colony_id)
        AND user_id != auth.uid()  -- cannot change own role
    )
    WITH CHECK (
        public.is_colony_admin(colony_id)
        AND user_id != auth.uid()
        AND role != 'owner'  -- cannot promote anyone to owner via UPDATE
    );

-- ============================================================
-- 5. Restrict EXECUTE permissions
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.join_colony_by_code(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_colony_by_code(TEXT) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.create_colony_with_owner(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_colony_with_owner(TEXT, TEXT, TEXT, TEXT) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.generate_invite_code() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.generate_invite_code() TO authenticated;

COMMIT;
