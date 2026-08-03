-- ============================================================
-- TCHAKA 2.0
-- Migration 038
-- Application acceptance workflow
-- ============================================================


-- ============================================================
-- 1. ACCEPT APPLICATION FUNCTION
-- ============================================================

create or replace function public.accept_project_application(
    p_application_id uuid,
    p_role text default 'contributor'
)
returns public.project_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_application public.project_applications;
    v_project public.projects;
begin

    -- --------------------------------------------------------
    -- Get application
    -- --------------------------------------------------------

    select *
    into v_application
    from public.project_applications
    where id = p_application_id
    for update;

    if not found then
        raise exception 'Application not found';
    end if;


    -- --------------------------------------------------------
    -- Get project
    -- --------------------------------------------------------

    select *
    into v_project
    from public.projects
    where id = v_application.project_id;

    if not found then
        raise exception 'Project not found';
    end if;


    -- --------------------------------------------------------
    -- Authorization
    -- --------------------------------------------------------

    if v_project.creator_id <> (select auth.uid()) then
        raise exception 'Only the project owner can accept applications';
    end if;


    -- --------------------------------------------------------
    -- Application state
    -- --------------------------------------------------------

    if v_application.status <> 'pending' then
        raise exception 'Only pending applications can be accepted';
    end if;


    -- --------------------------------------------------------
    -- Validate role
    -- --------------------------------------------------------

    if p_role not in (
        'owner',
        'admin',
        'developer',
        'designer',
        'marketing',
        'mentor',
        'contributor'
    ) then
        raise exception 'Invalid project member role';
    end if;


    -- --------------------------------------------------------
    -- Prevent duplicate membership
    -- --------------------------------------------------------

    if exists (
        select 1
        from public.project_members pm
        where pm.project_id = v_application.project_id
          and pm.profile_id = v_application.applicant_id
          and pm.status in ('pending', 'active')
    ) then
        raise exception 'Applicant is already a project member';
    end if;


    -- --------------------------------------------------------
    -- Create project membership
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
        p_role,
        'active',
        (select auth.uid()),
        now()
    );


    -- --------------------------------------------------------
    -- Accept application
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
-- 2. REJECT APPLICATION FUNCTION
-- ============================================================

create or replace function public.reject_project_application(
    p_application_id uuid
)
returns public.project_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_application public.project_applications;
    v_project_owner uuid;
begin

    select
        pa.*
    into v_application
    from public.project_applications pa
    where pa.id = p_application_id
    for update;

    if not found then
        raise exception 'Application not found';
    end if;


    select creator_id
    into v_project_owner
    from public.projects
    where id = v_application.project_id;


    if v_project_owner <> (select auth.uid()) then
        raise exception 'Only the project owner can reject applications';
    end if;


    if v_application.status <> 'pending' then
        raise exception 'Only pending applications can be rejected';
    end if;


    update public.project_applications
    set
        status = 'rejected',
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
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.accept_project_application(uuid, text)
from public, anon;

grant execute
on function public.accept_project_application(uuid, text)
to authenticated;


revoke execute
on function public.reject_project_application(uuid)
from public, anon;

grant execute
on function public.reject_project_application(uuid)
to authenticated;


-- ============================================================
-- 4. PERFORMANCE INDEX
-- ============================================================

create index if not exists project_applications_project_pending_idx
on public.project_applications (
    project_id,
    status,
    created_at desc
);


-- ============================================================
-- END OF MIGRATION 038
-- ============================================================
