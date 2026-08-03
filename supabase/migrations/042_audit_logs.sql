-- ============================================================
-- TCHAKA 2.0
-- Migration 042
-- Audit logs & security traceability
-- ============================================================


-- ============================================================
-- 1. AUDIT LOGS
-- ============================================================

create table if not exists public.audit_logs (
    id uuid primary key default gen_random_uuid(),

    actor_id uuid
        references public.profiles(id)
        on delete set null,

    action text not null,

    entity_type text,

    entity_id uuid,

    metadata jsonb not null default '{}'::jsonb,

    ip_address inet,

    user_agent text,

    created_at timestamptz not null default now(),

    constraint audit_logs_action_length
        check (
            char_length(action) between 2 and 100
        ),

    constraint audit_logs_entity_type_length
        check (
            entity_type is null
            or char_length(entity_type) between 2 and 100
        )
);


-- ============================================================
-- 2. INDEXES
-- ============================================================

create index if not exists audit_logs_actor_idx
on public.audit_logs (
    actor_id
);

create index if not exists audit_logs_action_idx
on public.audit_logs (
    action
);

create index if not exists audit_logs_entity_idx
on public.audit_logs (
    entity_type,
    entity_id
);

create index if not exists audit_logs_created_at_idx
on public.audit_logs (
    created_at desc
);

create index if not exists audit_logs_metadata_gin_idx
on public.audit_logs
using gin (
    metadata
);


-- ============================================================
-- 3. RLS
-- ============================================================

alter table public.audit_logs
enable row level security;


-- ============================================================
-- 4. NO NORMAL USER ACCESS
-- ============================================================

-- There is intentionally no SELECT/INSERT/UPDATE/DELETE
-- policy for normal authenticated users.
--
-- Audit records must be written only by trusted
-- server-side operations.


-- ============================================================
-- 5. TRUSTED AUDIT FUNCTION
-- ============================================================

create or replace function public.write_audit_log(
    p_action text,
    p_entity_type text default null,
    p_entity_id uuid default null,
    p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id uuid;
begin

    if p_action is null
       or char_length(trim(p_action)) < 2 then
        raise exception 'Invalid audit action';
    end if;


    insert into public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        metadata
    )
    values (
        (select auth.uid()),
        trim(p_action),
        nullif(trim(p_entity_type), ''),
        p_entity_id,
        coalesce(p_metadata, '{}'::jsonb)
    )
    returning id
    into v_id;


    return v_id;
end;
$$;


-- ============================================================
-- 6. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.write_audit_log(
    text,
    text,
    uuid,
    jsonb
)
from public, anon;

grant execute
on function public.write_audit_log(
    text,
    text,
    uuid,
    jsonb
)
to authenticated;


-- ============================================================
-- 7. PROTECT AUDIT TABLE
-- ============================================================

revoke all
on public.audit_logs
from anon, authenticated;


-- ============================================================
-- 8. END
-- ============================================================
