-- 005_join_colony_function.sql
-- Secure database function for joining a colony by invite code.
-- Runs as SECURITY DEFINER so it can bypass RLS to validate the code
-- and insert the membership row. Users cannot add themselves to
-- arbitrary colonies — they must provide a valid, unexpired code.
--
-- ROLLBACK: DROP FUNCTION IF EXISTS public.join_colony_by_code(TEXT);

CREATE OR REPLACE FUNCTION public.join_colony_by_code(p_code TEXT)
RETURNS UUID AS $$
DECLARE
    v_invite   RECORD;
    v_user_id  UUID := auth.uid();
    v_colony_id UUID;
BEGIN
    -- Must be authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Find the invite (case-insensitive)
    SELECT * INTO v_invite
    FROM public.colony_invites
    WHERE LOWER(code) = LOWER(TRIM(p_code));

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid invite code';
    END IF;

    v_colony_id := v_invite.colony_id;

    -- Check expiry
    IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < now() THEN
        RAISE EXCEPTION 'Invite code has expired';
    END IF;

    -- Check max uses
    IF v_invite.max_uses IS NOT NULL AND v_invite.uses >= v_invite.max_uses THEN
        RAISE EXCEPTION 'Invite code has reached its maximum uses';
    END IF;

    -- Check if already a member
    IF EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = v_colony_id AND user_id = v_user_id AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'You are already a member of this colony';
    END IF;

    -- Insert membership
    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_user_id, 'member', 'active')
    ON CONFLICT (colony_id, user_id) DO UPDATE
        SET status = 'active', role = 'member', updated_at = now();

    -- Increment invite use count
    UPDATE public.colony_invites SET uses = uses + 1 WHERE id = v_invite.id;

    RETURN v_colony_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
