-- ============================================================
-- TCHAKA 2.0
-- Migration 017
-- Auth profile automation
-- ============================================================

-- ============================================================
-- 1. CREATE PROFILE AFTER AUTH SIGNUP
--
-- Every new authenticated user automatically receives a
-- corresponding public.profiles row.
--
-- The profile ID is exactly the auth.users ID.
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

        nullif(
            coalesce(
                new.raw_user_meta_data ->> 'username',
                ''
            ),
            ''
        ),

        nullif(
            coalesce(
                new.raw_user_meta_data ->> 'full_name',
                new.raw_user_meta_data ->> 'name',
                ''
            ),
            ''
        ),

        nullif(
            coalesce(
                new.raw_user_meta_data ->> 'avatar_url',
                ''
            ),
            ''
        )
    )

    on conflict (id) do nothing;

    return new;
end;
$$;


-- ============================================================
-- 2. TRIGGER
-- ============================================================

drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();


-- ============================================================
-- 3. FUNCTION PRIVILEGES
--
-- The trigger executes internally.
-- Clients must not call this function directly.
-- ============================================================

revoke execute
on function public.handle_new_user()
from public, anon, authenticated;


-- ============================================================
-- 4. PROFILE UPDATE PROTECTION
--
-- updated_at is already managed by migration 016.
-- ============================================================

-- Ensure profiles remain protected by RLS.
alter table public.profiles enable row level security;


-- ============================================================
-- 5. PROFILE CONSISTENCY INDEX
-- ============================================================

create index if not exists profiles_created_at_idx
on public.profiles (
    created_at desc
);


-- ============================================================
-- END OF MIGRATION 017
-- ============================================================
