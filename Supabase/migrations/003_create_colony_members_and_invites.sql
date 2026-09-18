-- 003_create_colony_members_and_invites.sql
-- Normalized membership table + invite-code table.
--
-- ROLLBACK: DROP TABLE IF EXISTS public.colony_invites CASCADE;
--           DROP TABLE IF EXISTS public.colony_members CASCADE;

-- Colony members -----------------------------------------------------------

CREATE TABLE public.colony_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    colony_id   UUID NOT NULL REFERENCES public.colonies(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role        TEXT NOT NULL DEFAULT 'member'
                    CHECK (role IN ('owner','admin','member')),
    status      TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','invited','removed')),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (colony_id, user_id)
);

-- Fast lookups: "which colonies does this user belong to?"
CREATE INDEX idx_colony_members_user_id ON public.colony_members (user_id);
-- Fast lookups: "who is in this colony?"
CREATE INDEX idx_colony_members_colony_id ON public.colony_members (colony_id);
-- Active members only
CREATE INDEX idx_colony_members_active ON public.colony_members (colony_id, status) WHERE status = 'active';

CREATE TRIGGER colony_members_updated_at
    BEFORE UPDATE ON public.colony_members
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Colony invites (join codes) ----------------------------------------------

CREATE TABLE public.colony_invites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    colony_id   UUID NOT NULL REFERENCES public.colonies(id) ON DELETE CASCADE,
    code        TEXT NOT NULL,
    created_by  UUID NOT NULL REFERENCES public.profiles(id),
    uses        INT NOT NULL DEFAULT 0,
    max_uses    INT,                     -- NULL = unlimited
    expires_at  TIMESTAMPTZ,             -- NULL = never expires
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique, case-insensitive 6-char codes
CREATE UNIQUE INDEX idx_colony_invites_code_lower ON public.colony_invites (LOWER(code));
CREATE INDEX idx_colony_invites_colony_id ON public.colony_invites (colony_id);

-- RLS on both tables (policies in next migration) --------------------------

ALTER TABLE public.colony_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colony_invites ENABLE ROW LEVEL SECURITY;
