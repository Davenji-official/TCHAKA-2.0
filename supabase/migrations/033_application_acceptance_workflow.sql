-- ============================================================
-- TCHAKA 2.0
-- Migration 033
-- Application acceptance workflow
-- ============================================================


-- ============================================================
-- 1. ACCEPT APPLICATION + ADD PROJECT MEMBER
-- ============================================================

create or replace function public.accept_project_application(
    p_application_id uuid
)
returns public.project_applications
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_application public.project_applications;
    v_project_creator uuid;
begin

    -- --------------------------------------------------------
    -- Find the application and verify project ownership
    -- --------------------------------------------------------

    select
        pa.*
    into v_application
    from public.project_applications pa
    where pa.id = p_application_id
      and public.is_project_owner(
          pa.project_id,
          (select auth.uid())
      )
    for update;

    if v_application.id is null then
        raise exception 'Application not found or unauthorized';
    end if;


    -- --------------------------------------------------------
    -- Prevent invalid transitions
    -- --------------------------------------------------------

    if v_application.status = 'accepted' then
        return v_application;
    end if;

    if v_application.status in (
        'rejected',
        'withdrawn'
    ) then
        raise exception 'Application cannot be accepted from its current status';
    end if;


    -- --------------------------------------------------------
    -- Get project creator
    -- --------------------------------------------------------

    select p.creator_id
    into v_project_creator
    from public.projects p
    where p.id = v_application.project_id;

    if v_project_creator is null then
        raise exception 'Project not found';
    end if;


    -- --------------------------------------------------------
    -- Add applicant as active project member
    -- --------------------------------------------------------

    insert into public.project_members (
        project_id,
        profile_id,
        role,
        status,
        invited_by,
        joined_at
    )
    values (
        v_application.project_id,
        v_application.applicant_id,
        coalesce(
            nullif(trim(v_application.proposed_role), ''),
            'contributor'
        ),
        'active',
        v_project_creator,
        now()
    )
    on conflict (
        project_id,
        profile_id
    )
    do update
    set
        status = 'active',
        role = excluded.role,
        invited_by = excluded.invited_by,
        joined_at = coalesce(
            public.project_members.joined_at,
            excluded.joined_at
        );


    -- --------------------------------------------------------
    -- Mark application accepted
    -- --------------------------------------------------------

    update public.project_applications
    set
        status = 'accepted',
        reviewed_by = (select auth.uid()),
        reviewed_at = now(),
        updated_at = now()
    where id = p_application_id
    returning *
    into v_application;


    return v_application;
end;
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.accept_project_application(uuid)
from public, anon;

grant execute
on function public.accept_project_application(uuid)
to authenticated;


-- ============================================================
-- 3. REJECT APPLICATION
-- ============================================================

create or replace function public.reject_project_application(
    p_application_id uuid
)
returns public.project_applications
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_application public.project_applications;
begin

    update public.project_applications
    set
        status = 'rejected',
        reviewed_by = (select auth.uid()),
        reviewed_at = now(),
        updated_at = now()
    where id = p_application_id
      and public.is_project_owner(
          project_id,
          (select auth.uid())
      )
      and status in (
          'pending',
          'reviewing'
      )
    returning *
    into v_application;


    if v_application.id is null then
        raise exception 'Application not found, unauthorized, or invalid status';
    end if;


    return v_application;
end;
$$;


-- ============================================================
-- 4. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.reject_project_application(uuid)
from public, anon;

grant execute
on function public.reject_project_application(uuid)
to authenticated;


-- ============================================================
-- 5. REVIEW APPLICATION
-- ============================================================

create or replace function public.review_project_application(
    p_application_id uuid,
    p_status text
)
returns public.project_applications
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_application public.project_applications;
begin

    if p_status = 'accepted' then
        return public.accept_project_application(
            p_application_id
        );
    end if;


    if p_status = 'rejected' then
        return public.reject_project_application(
            p_application_id
        );
    end if;


    if p_status <> 'reviewing' then
        raise exception 'Invalid application status';
    end if;


    update public.project_applications
    set
        status = 'reviewing',
        reviewed_by = (select auth.uid()),
        updated_at = now()
    where id = p_application_id
      and public.is_project_owner(
          project_id,
          (select auth.uid())
      )
      and status = 'pending'
    returning *
    into v_application;


    if v_application.id is null then
        raise exception 'Application not found, unauthorized, or invalid status';
    end if;


    return v_application;
end;
$$;


-- ============================================================
-- 6. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.review_project_application(
    uuid,
    text
)
from public, anon;

grant execute
on function public.review_project_application(
    uuid,
    text
)
to authenticated;


-- ============================================================
-- END OF MIGRATION 033
-- ============================================================
