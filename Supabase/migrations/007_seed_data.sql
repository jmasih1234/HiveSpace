-- 007_seed_data.sql
-- Local testing seed data. Run AFTER creating two test users via Supabase Auth.
-- Replace the UUIDs below with real auth.users IDs from your local Supabase dashboard.
--
-- Test accounts (create these in Auth > Users or via the app's sign-up flow):
--   User A: alice@test.com / Password123!
--   User B: bob@test.com   / Password123!
--
-- After creating users, copy their auth.users.id values into the variables below.
-- The handle_new_user trigger will have already created their profiles.
--
-- ROLLBACK: DELETE FROM public.colony_invites;
--           DELETE FROM public.colony_members;
--           DELETE FROM public.colonies;
--           (profiles are auto-managed by auth trigger)

-- ⚠️  INSTRUCTIONS:
-- 1. Create User A and User B through the app or Supabase dashboard.
-- 2. Run: SELECT id, email FROM auth.users;
-- 3. Replace the placeholder UUIDs below.
-- 4. Execute this file in the SQL Editor.

DO $$
DECLARE
    -- Replace with real user IDs from auth.users
    v_alice UUID := '00000000-0000-0000-0000-000000000001';  -- alice@test.com
    v_bob   UUID := '00000000-0000-0000-0000-000000000002';  -- bob@test.com
    v_colony_id UUID;
    v_code TEXT;
BEGIN
    -- Update Alice's profile
    UPDATE public.profiles
    SET display_name = 'Alice', username = 'alice'
    WHERE id = v_alice;

    -- Update Bob's profile
    UPDATE public.profiles
    SET display_name = 'Bob', username = 'bob'
    WHERE id = v_bob;

    -- Create a colony owned by Alice
    INSERT INTO public.colonies (name, emoji, description, type, created_by)
    VALUES ('The Hive', '🐝', 'Alice and Bob''s shared apartment', 'Roommates', v_alice)
    RETURNING id INTO v_colony_id;

    -- Alice is the owner
    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_alice, 'owner', 'active');

    -- Bob is a member
    INSERT INTO public.colony_members (colony_id, user_id, role, status)
    VALUES (v_colony_id, v_bob, 'member', 'active');

    -- Create an invite code
    v_code := public.generate_invite_code();
    INSERT INTO public.colony_invites (colony_id, code, created_by)
    VALUES (v_colony_id, v_code, v_alice);

    RAISE NOTICE 'Seed complete. Colony ID: %, Invite code: %', v_colony_id, v_code;
END $$;
