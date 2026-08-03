-- ============================================================
-- TCHAKA 2.0
-- Migration 021
-- Profile automation and integrity
-- ============================================================


-- ============================================================
-- 1. UPDATED_AT HELPER
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;


-- ============================================================
-- 2. PROFILE AUTO-CREATION
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin

    insert into public.profiles (
        id,
        username,
        full_name,
        avatar_url
    )
    values (
        new.id,
        null,
        coalesce(
            nullif(new.raw_user_meta_data ->> 'full_name', ''),
            nullif(new.raw_user_meta_data ->> 'name', '')
        ),
        nullif(new.raw_user_meta_data ->> 'avatar_url', '')
    )
    on conflict (id) do nothing;

    return new;
end;
$$;


-- ============================================================
-- 3. PROFILE CREATION TRIGGER
-- ============================================================

drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();


-- ============================================================
-- 4. UPDATED_AT TRIGGER
-- ============================================================

drop trigger if exists profiles_set_updated_at
on public.profiles;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();


-- ============================================================
-- 5. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.set_updated_at()
from public, anon, authenticated;

revoke execute
on function public.handle_new_user()
from public, anon, authenticated;


-- ============================================================
-- 6. PROTECT SYSTEM PROFILE FIELDS
-- ============================================================
--
-- Users must NOT be able to promote themselves to:
--
-- is_verified = true
-- is_premium  = true
--
-- These fields will later be controlled by trusted
-- administrative/backend mechanisms.
--
-- ============================================================

create or replace function public.protect_profile_system_fields()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin

    if old.is_verified is distinct from new.is_verified then
        raise exception 'is_verified can only be changed by a trusted system';
    end if;

    if old.is_premium is distinct from new.is_premium then
        raise exception 'is_premium can only be changed by a trusted system';
    end if;

    return new;
end;
$$;


drop trigger if exists protect_profile_system_fields
on public.profiles;

create trigger protect_profile_system_fields
before update on public.profiles
for each row
execute function public.protect_profile_system_fields();


revoke execute
on function public.protect_profile_system_fields()
from public, anon, authenticated;


-- ============================================================
-- 7. BACKFILL MISSING PROFILES
-- ============================================================
--
-- Creates profiles for existing Auth users that do not
-- currently have a corresponding profile.
--
-- ============================================================

insert into public.profiles (
    id,
    full_name,
    avatar_url
)
select
    u.id,
    coalesce(
        nullif(u.raw_user_meta_data ->> 'full_name', ''),
        nullif(u.raw_user_meta_data ->> 'name', '')
    ),
    nullif(u.raw_user_meta_data ->> 'avatar_url', '')
from auth.users u
left join public.profiles p
    on p.id = u.id
where p.id is null
on conflict (id) do nothing;


-- ============================================================
-- 8. PROFILE INDEX
-- ============================================================

create index if not exists profiles_created_at_idx
on public.profiles (created_at desc);


-- ============================================================
-- END OF MIGRATION 021
-- ============================================================
