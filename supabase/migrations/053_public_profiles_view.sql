-- ============================================================
-- TCHAKA 2.0
-- Migration 053
-- Public profile read model
-- ============================================================

-- The Flutter profile screen reads from public_profiles. Keep this
-- view intentionally limited to fields safe for public discovery.
create or replace view public.public_profiles
with (security_invoker = false)
as
select
    p.id,
    p.username,
    p.full_name,
    p.avatar_url,
    p.bio,
    p.country,
    p.city,
    p.is_verified,
    p.is_premium,
    p.created_at,
    p.updated_at
from public.profiles as p;

comment on view public.public_profiles is
    'Safe public projection of profile data used by TCHAKA discovery and profile screens.';

grant select on public.public_profiles to anon, authenticated;
