-- ============================================================
-- TCHAKA 2.0
-- Migration 043
-- Final database hardening
-- ============================================================


-- ============================================================
-- 1. PROTECT PUBLIC SCHEMA DEFAULTS
-- ============================================================

revoke create
on schema public
from anon, authenticated;


-- ============================================================
-- 2. ENSURE RLS IS ENABLED ON ALL APPLICATION TABLES
-- ============================================================

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.profile_roles enable row level security;

alter table public.skills enable row level security;
alter table public.user_skills enable row level security;

alter table public.projects enable row level security;
alter table public.project_skills enable row level security;

alter table public.follows enable row level security;
alter table public.project_likes enable row level security;
alter table public.project_bookmarks enable row level security;

alter table public.comments enable row level security;
alter table public.project_media enable row level security;
alter table public.notifications enable row level security;

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_attachments enable row level security;

alter table public.project_members enable row level security;

alter table public.funding_campaigns enable row level security;
alter table public.funding_contributions enable row level security;

alter table public.reports enable row level security;
alter table public.audit_logs enable row level security;


-- ============================================================
-- 3. SECURITY FUNCTIONS
-- ============================================================

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
    select auth.uid();
$$;


-- ============================================================
-- 4. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.current_profile_id()
from public, anon;

grant execute
on function public.current_profile_id()
to authenticated;


-- ============================================================
-- 5. FINAL SECURITY ASSERTIONS
-- ============================================================

do $$
declare
    v_table text;
    v_rls boolean;
begin

    foreach v_table in array array[
        'profiles',
        'roles',
        'profile_roles',
        'skills',
        'user_skills',
        'projects',
        'project_skills',
        'follows',
        'project_likes',
        'project_bookmarks',
        'comments',
        'project_media',
        'notifications',
        'conversations',
        'conversation_members',
        'messages',
        'message_attachments',
        'project_members',
        'funding_campaigns',
        'funding_contributions',
        'reports',
        'audit_logs'
    ]
    loop

        select c.relrowsecurity
        into v_rls
        from pg_class c
        join pg_namespace n
            on n.oid = c.relnamespace
        where n.nspname = 'public'
          and c.relname = v_table;

        if coalesce(v_rls, false) = false then
            raise exception
                'Security assertion failed: RLS disabled on public.%', v_table;
        end if;

    end loop;

end;
$$;


-- ============================================================
-- 6. END OF DATABASE FOUNDATION
-- ============================================================

-- Migration 043 intentionally contains no application data.
-- It only finalizes the security baseline of the database.
