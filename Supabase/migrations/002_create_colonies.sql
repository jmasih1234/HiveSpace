-- 002_create_colonies.sql
-- Creates colonies table with settings stored as JSONB.
--
-- ROLLBACK: DROP TABLE IF EXISTS public.colonies CASCADE;

CREATE TABLE public.colonies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         TEXT NOT NULL,
    emoji        TEXT NOT NULL DEFAULT '🐝',
    description  TEXT,
    type         TEXT NOT NULL DEFAULT 'Roommates'
                     CHECK (type IN ('Roommates','Project','Friend Group','Family','Team')),
    created_by   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    settings     JSONB NOT NULL DEFAULT '{
        "is_public": false,
        "allow_guest_view": false,
        "default_split_method": "equal",
        "semester_mode": false,
        "nudges_enabled": true,
        "currency_code": "USD"
    }'::jsonb,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_colonies_created_by ON public.colonies (created_by);

CREATE TRIGGER colonies_updated_at
    BEFORE UPDATE ON public.colonies
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS ----------------------------------------------------------------------

ALTER TABLE public.colonies ENABLE ROW LEVEL SECURITY;

-- Members can read colonies they belong to (policy references colony_members, created next)
-- Deferred until after colony_members table exists; see 003.
-- Colony creator can update their colony
-- Deferred to 004_rls_policies.sql after all tables exist.
