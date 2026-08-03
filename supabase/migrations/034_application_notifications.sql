-- ============================================================
-- TCHAKA 2.0
-- Migration 034
-- Application notifications
-- ============================================================


-- ============================================================
-- 1. CREATE NOTIFICATION HELPER
-- ============================================================

create or replace function public.create_notification(
    p_recipient_id uuid,
    p_actor_id uuid,
    p_type text,
    p_title text,
    p_body text default null,
    p_entity_type text default null,
    p_entity_id uuid default null
)
returns public.notifications
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_notification public.notifications;
begin

    if p_recipient_id is null then
        raise exception 'Notification recipient is required';
    end if;

    if p_type not in (
        'like',
        'comment',
        'follow',
        'message',
        'funding',
        'project_update',
        'team_invite',
        'verification',
        'system'
    ) then
        raise exception 'Invalid notification type';
    end if;

    if p_title is null
       or char_length(trim(p_title)) = 0 then
        raise exception 'Notification title is required';
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
        p_recipient_id,
        p_actor_id,
        p_type,
        p_title,
        p_body,
        p_entity_type,
        p_entity_id
    )
    returning *
    into v_notification;


    return v_notification;
end;
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.create_notification(
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    uuid
)
from public, anon;

grant execute
on function public.create_notification(
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    uuid
)
to authenticated;


-- ============================================================
-- 3. APPLICATION CREATED
-- ============================================================

create or replace function public.notify_project_application(
    p_application_id uuid
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_project_creator uuid;
    v_applicant_id uuid;
    v_project_id uuid;
    v_project_title text;
begin

    select
        pa.applicant_id,
        pa.project_id,
        p.creator_id,
        p.title
    into
        v_applicant_id,
        v_project_id,
        v_project_creator,
        v_project_title
    from public.project_applications pa
    join public.projects p
        on p.id = pa.project_id
    where pa.id = p_application_id;


    if v_project_creator is null then
        raise exception 'Application or project not found';
    end if;


    if v_project_creator = v_applicant_id then
        return;
    end if;


    perform public.create_notification(
        v_project_creator,
        v_applicant_id,
        'team_invite',
        'Nouvelle candidature',
        'Un utilisateur a postulé à votre projet "' ||
            v_project_title ||
            '".',
        'project_application',
        p_application_id
    );

end;
$$;


-- ============================================================
-- 4. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.notify_project_application(uuid)
from public, anon;

grant execute
on function public.notify_project_application(uuid)
to authenticated;


-- ============================================================
-- 5. APPLICATION DECISION NOTIFICATION
-- ============================================================

create or replace function public.notify_application_decision(
    p_application_id uuid,
    p_status text
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_applicant_id uuid;
    v_project_id uuid;
    v_project_title text;
    v_creator_id uuid;
begin

    if p_status not in (
        'accepted',
        'rejected'
    ) then
        raise exception 'Invalid application decision';
    end if;


    select
        pa.applicant_id,
        pa.project_id,
        p.title,
        p.creator_id
    into
        v_applicant_id,
        v_project_id,
        v_project_title,
        v_creator_id
    from public.project_applications pa
    join public.projects p
        on p.id = pa.project_id
    where pa.id = p_application_id;


    if v_applicant_id is null then
        raise exception 'Application or project not found';
    end if;


    if p_status = 'accepted' then

        perform public.create_notification(
            v_applicant_id,
            v_creator_id,
            'team_invite',
            'Candidature acceptée',
            'Votre candidature pour le projet "' ||
                v_project_title ||
                '" a été acceptée.',
            'project_application',
            p_application_id
        );

    else

        perform public.create_notification(
            v_applicant_id,
            v_creator_id,
            'system',
            'Candidature refusée',
            'Votre candidature pour le projet "' ||
                v_project_title ||
                '" n''a pas été retenue.',
            'project_application',
            p_application_id
        );

    end if;

end;
$$;


-- ============================================================
-- 6. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.notify_application_decision(
    uuid,
    text
)
from public, anon;

grant execute
on function public.notify_application_decision(
    uuid,
    text
)
to authenticated;


-- ============================================================
-- 7. TRIGGER — NEW APPLICATION
-- ============================================================

create or replace function public.trigger_notify_new_application()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin

    perform public.notify_project_application(
        new.id
    );

    return new;
end;
$$;


drop trigger if exists trg_notify_new_application
on public.project_applications;


create trigger trg_notify_new_application
after insert on public.project_applications
for each row
execute function public.trigger_notify_new_application();


-- ============================================================
-- 8. TRIGGER — APPLICATION DECISION
-- ============================================================

create or replace function public.trigger_notify_application_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin

    if new.status in (
        'accepted',
        'rejected'
    )
    and old.status is distinct from new.status then

        perform public.notify_application_decision(
            new.id,
            new.status
        );

    end if;

    return new;
end;
$$;


drop trigger if exists trg_notify_application_decision
on public.project_applications;


create trigger trg_notify_application_decision
after update of status
on public.project_applications
for each row
execute function public.trigger_notify_application_decision();


-- ============================================================
-- 9. SECURITY DEFINER TRIGGER PRIVILEGES
-- ============================================================

revoke execute
on function public.trigger_notify_new_application()
from public, anon, authenticated;

revoke execute
on function public.trigger_notify_application_decision()
from public, anon, authenticated;


-- ============================================================
-- 10. PERFORMANCE INDEX
-- ============================================================

create index if not exists notifications_entity_idx
on public.notifications (
    entity_type,
    entity_id
);


-- ============================================================
-- END OF MIGRATION 034
-- ============================================================
