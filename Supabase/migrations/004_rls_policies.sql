-- 004_rls_policies.sql
-- Row-level security policies for colonies, colony_members, colony_invites.
-- All cross-table membership checks go through colony_members.
--
-- ROLLBACK: Run DROP POLICY statements below for each policy name.

-- Helper: is the current user an active member of a colony? ----------------

CREATE OR REPLACE FUNCTION public.is_colony_member(p_colony_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = p_colony_id
          AND user_id = auth.uid()
          AND status = 'active'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: is the current user owner or admin of a colony? ------------------

CREATE OR REPLACE FUNCTION public.is_colony_admin(p_colony_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.colony_members
        WHERE colony_id = p_colony_id
          AND user_id = auth.uid()
          AND status = 'active'
          AND role IN ('owner','admin')
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ═══════════════ colonies policies ═══════════════════════════════════════

-- Members can read colonies they belong to
CREATE POLICY "Members can read own colonies"
    ON public.colonies FOR SELECT
    USING (public.is_colony_member(id));

-- Only the creator can INSERT (colony creation handled by function below)
CREATE POLICY "Creator can insert colony"
    ON public.colonies FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Owner/admin can update colony settings
CREATE POLICY "Admins can update colony"
    ON public.colonies FOR UPDATE
    USING (public.is_colony_admin(id))
    WITH CHECK (public.is_colony_admin(id));

-- Only owner can delete
CREATE POLICY "Owner can delete colony"
    ON public.colonies FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.colony_members
            WHERE colony_id = id
              AND user_id = auth.uid()
              AND role = 'owner'
              AND status = 'active'
        )
    );

-- ═══════════════ colony_members policies ═════════════════════════════════

-- Members can see other members in their colonies
CREATE POLICY "Members can read colony members"
    ON public.colony_members FOR SELECT
    USING (public.is_colony_member(colony_id));

-- Only admin/owner can add members (NOT self-add; join-by-code uses a secure function)
CREATE POLICY "Admins can insert members"
    ON public.colony_members FOR INSERT
    WITH CHECK (public.is_colony_admin(colony_id));

-- Admin/owner can update roles/status (but not their own role downgrade — app-level check)
CREATE POLICY "Admins can update members"
    ON public.colony_members FOR UPDATE
    USING (public.is_colony_admin(colony_id))
    WITH CHECK (public.is_colony_admin(colony_id));

-- Admin/owner can remove members
CREATE POLICY "Admins can delete members"
    ON public.colony_members FOR DELETE
    USING (public.is_colony_admin(colony_id));

-- A member can remove themselves (leave colony)
CREATE POLICY "Members can remove themselves"
    ON public.colony_members FOR DELETE
    USING (user_id = auth.uid());

-- ═══════════════ colony_invites policies ═════════════════════════════════

-- Members can see invite codes for their colonies
CREATE POLICY "Members can read invite codes"
    ON public.colony_invites FOR SELECT
    USING (public.is_colony_member(colony_id));

-- Admin/owner can create invite codes
CREATE POLICY "Admins can create invite codes"
    ON public.colony_invites FOR INSERT
    WITH CHECK (public.is_colony_admin(colony_id));

-- Admin/owner can revoke invite codes
CREATE POLICY "Admins can delete invite codes"
    ON public.colony_invites FOR DELETE
    USING (public.is_colony_admin(colony_id));
