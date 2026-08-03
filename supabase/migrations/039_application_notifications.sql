-- ============================================================
-- TCHAKA 2.0
-- Migration 039
-- Application notifications
-- ============================================================


-- ============================================================
-- 1. APPLICATION CREATED NOTIFICATION
-- ============================================================

create or replace function public.notify_project_application_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_owner uuid;
    v_project_title text;
    v_applicant_name text;
begin

    select
        p.creator_id,
        p.title
    into
        v_project_owner,
        v_project_title
    from public.projects p
    where p.id = new.project_id;


    select
        coalesce(
            nullif(trim(pr.full_name), ''),
            nullif(trim(pr.username), ''),
            'Un utilisateur'
        )
    into v_applicant_name
    from public.profiles pr
    where pr.id = new.applicant_id;


    if v_project_owner is not null
       and v_project_owner <> new.applicant_id then

        insert into public.notifications (
            recipient_id,
            actor_id,
            type,
            title,
            body,
            entity_type,
            entity_id
        )
        values (
            v_project_owner,
            new.applicant_id,
            'project_update',
            'Nouvelle candidature',
            v_applicant_name
                || ' a candidaté à votre projet « '
                || v_project_title
                || ' ».',
            'project_application',
            new.id
        );

    end if;


    return new;
end;
$$;


drop trigger if exists project_application_created_notification
on public.project_applications;


create trigger project_application_created_notification
after insert on public.project_applications
for each row
execute function public.notify_project_application_created();


-- ============================================================
-- 2. APPLICATION STATUS NOTIFICATION
-- ============================================================

create or replace function public.notify_project_application_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_title text;
    v_title text;
    v_body text;
begin

    if old.status = new.status then
        return new;
    end if;


    select title
    into v_project_title
    from public.projects
    where id = new.project_id;


    if new.status = 'accepted' then

        v_title := 'Candidature acceptée';

        v_body :=
            'Votre candidature pour le projet « '
            || v_project_title
            || ' » a été acceptée.';


    elsif new.status = 'rejected' then

        v_title := 'Candidature refusée';

        v_body :=
            'Votre candidature pour le projet « '
            || v_project_title
            || ' » a été refusée.';


    elsif new.status = 'withdrawn' then

        v_title := 'Candidature retirée';

        v_body :=
            'Votre candidature pour le projet « '
            || v_project_title
            || ' » a été retirée.';

    else

        return new;

    end if;


    insert into public.notifications (
        recipient_id,
        actor_id,
        type,
        title,
        body,
        entity_type,
        entity_id
    )
    values (
        new.applicant_id,
        coalesce(new.reviewed_by, new.applicant_id),
        'project_update',
        v_title,
        v_body,
        'project_application',
        new.id
    );


    return new;
end;
$$;


drop trigger if exists project_application_status_notification
on public.project_applications;


create trigger project_application_status_notification
after update of status
on public.project_applications
for each row
execute function public.notify_project_application_status();


-- ============================================================
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.notify_project_application_created()
from public, anon;

revoke execute
on function public.notify_project_application_status()
from public, anon;


-- ============================================================
-- 4. PERFORMANCE INDEX
-- ============================================================

create index if not exists notifications_entity_idx
on public.notifications (
    entity_type,
    entity_id
);


-- ============================================================
-- END OF MIGRATION 039
-- ============================================================
