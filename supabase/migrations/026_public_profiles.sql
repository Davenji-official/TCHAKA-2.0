-- ============================================================
-- TCHAKA 2.0
-- Migration 026
-- Public profile access
-- ============================================================

-- ============================================================
-- 1. PUBLIC PROFILE VIEW
-- ============================================================

create or replace view public.public_profiles
with (security_invoker = true)
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
    p.created_at
from public.profiles p;


-- ============================================================
-- 2. VIEW ACCESS
-- ============================================================

revoke all
on public.public_profiles
from anon;

revoke all
on public.public_profiles
from public;

grant select
on public.public_profiles
to authenticated;


-- ============================================================
-- 3. PROFILE SEARCH INDEXES
-- ============================================================

create index if not exists profiles_full_name_idx
on public.profiles (full_name);

create index if not exists profiles_created_at_idx
on public.profiles (created_at desc);

create index if not exists profiles_verified_idx
on public.profiles (is_verified);

create index if not exists profiles_premium_idx
on public.profiles (is_premium);


-- ============================================================
-- 4. END
-- ============================================================
