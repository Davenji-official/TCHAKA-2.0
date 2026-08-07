-- ============================================================
-- TCHAKA 2.0
-- Migration 050
-- Application review workflow
-- ============================================================

create or replace function public.review_project_application(
    p_application_id uuid,
    p_status text
)
returns public.project_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_application public.project_applications;
    v_project_owner uuid;
    v_status text := lower(trim(p_status));
begin
    if v_status <> 'reviewing' then
        raise exception 'Only the reviewing status is handled by this function';
    end if;

    select pa.*
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
        raise exception 'Only the project owner can review applications';
    end if;

    if v_application.status <> 'pending' then
        raise exception 'Only pending applications can enter review';
    end if;

    update public.project_applications
    set
        status = 'reviewing',
        reviewed_by = (select auth.uid()),
        reviewed_at = now(),
        updated_at = now()
    where id = p_application_id
    returning *
    into v_application;

    return v_application;
end;
$$;

revoke execute
on function public.review_project_application(uuid, text)
from public, anon;

grant execute
on function public.review_project_application(uuid, text)
to authenticated;

-- ============================================================
-- END OF MIGRATION 050
-- ============================================================
