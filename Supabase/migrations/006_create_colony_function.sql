-- 006_create_colony_function.sql
-- Secure function to create a colony + owner membership + default invite code
-- in a single transaction. Generates a unique 6-character invite code.
--
-- ROLLBACK: DROP FUNCTION IF EXISTS public.create_colony(TEXT, TEXT, TEXT, TEXT, JSONB);
--           DROP FUNCTION IF EXISTS public.generate_invite_code();

-- Generate a random 6-char alphanumeric code (uppercase, no ambiguous chars)
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- no I,O,0,1
    code  TEXT := '';
    i     INT;
BEGIN
    FOR i IN 1..6 LOOP
        code := code || SUBSTR(chars, FLOOR(RANDOM() * LENGTH(chars) + 1)::INT, 1);
    END LOOP;
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Create colony with owner membership and invite code
CREATE OR REPLACE FUNCTION public.create_colony_with_owner(
    p_name     TEXT,
    p_emoji    TEXT DEFAULT '🐝',
    p_description TEXT DEFAULT NULL,
    p_type     TEXT DEFAULT 'Roommates',
    p_settings JSONB DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_user_id   UUID := auth.uid();
    v_colony_id UUID;
    v_code      TEXT;
    v_settings  JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Default settings
    v_settings := COALESCE(p_settings, '{
        "is_public": false,
        "allow_guest_view": false,
        "default_split_method": "equal",
        "semester_mode": false,
        "nudges_enabled": true,
        "currency_code": "USD"
    }'::jsonb);

    -- Create colony
    INSERT INTO public.colonies (name, emoji, description, type, created_by, settings)
    VALUES (p_name, p_emoji, p_description, p_type, v_user_id, v_settings)
    RETURNING id INTO v_colony_id;

    -- Add creator as owner
    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_user_id, 'owner', 'active');

    -- Generate unique invite code
    LOOP
        v_code := public.generate_invite_code();
        BEGIN
            INSERT INTO public.colony_invites (colony_id, code, created_by)
            VALUES (v_colony_id, v_code, v_user_id);
            EXIT; -- success
        EXCEPTION WHEN unique_violation THEN
            -- try again with a new code
        END;
    END LOOP;

    -- Return colony id and invite code
    RETURN json_build_object(
        'colony_id', v_colony_id,
        'invite_code', v_code
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
