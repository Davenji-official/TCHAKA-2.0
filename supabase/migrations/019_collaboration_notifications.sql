-- ============================================================
-- TCHAKA 2.0
-- Migration 019
-- Collaboration notifications
-- ============================================================


-- ============================================================
-- 1. PROJECT INVITATION NOTIFICATION
-- ============================================================

create or replace function public.notify_project_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_title text;
    v_inviter_name text;
begin

    -- Only notify when an invitation is created as pending.
    if new.status <> 'pending' then
        return new;
    end if;

    select p.title
    into v_project_title
    from public.projects p
    where p.id = new.project_id;

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_inviter_name
    from public.profiles p
    where p.id = new.invited_by;

    -- Do not notify if the target user is the inviter.
    if new.profile_id = new.invited_by then
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
        new.profile_id,
        new.invited_by,
        'team_invite',
        'Invitation à rejoindre un projet',
        v_inviter_name
            || ' vous invite à rejoindre le projet « '
            || coalesce(v_project_title, 'Projet')
            || ' ».',
        'project',
        new.project_id
    );

    return new;
end;
$$;


drop trigger if exists project_invitation_notification
on public.project_members;

create trigger project_invitation_notification
after insert on public.project_members
for each row
execute function public.notify_project_invitation();


-- ============================================================
-- 2. PROJECT INVITATION RESPONSE NOTIFICATION
-- ============================================================

create or replace function public.notify_project_invitation_response()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_title text;
    v_member_name text;
    v_notification_title text;
    v_notification_body text;
begin

    -- Only react when a pending invitation becomes active
    -- or declined.
    if old.status <> 'pending'
       or new.status not in ('active', 'declined') then
        return new;
    end if;

    -- Prevent duplicate notifications.
    if old.status = new.status then
        return new;
    end if;

    -- The owner/inviter is the project creator.
    select p.title
    into v_project_title
    from public.projects p
    where p.id = new.project_id;

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_member_name
    from public.profiles p
    where p.id = new.profile_id;

    if new.status = 'active' then

        v_notification_title := 'Invitation acceptée';

        v_notification_body :=
            v_member_name
            || ' a accepté votre invitation à rejoindre « '
            || coalesce(v_project_title, 'Projet')
            || ' ».';

    else

        v_notification_title := 'Invitation refusée';

        v_notification_body :=
            v_member_name
            || ' a refusé votre invitation à rejoindre « '
            || coalesce(v_project_title, 'Projet')
            || ' ».';

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
    select
        p.creator_id,
        new.profile_id,
        'team_invite',
        v_notification_title,
        v_notification_body,
        'project',
        new.project_id
    from public.projects p
    where p.id = new.project_id
      and p.creator_id <> new.profile_id;

    return new;
end;
$$;


drop trigger if exists project_invitation_response_notification
on public.project_members;

create trigger project_invitation_response_notification
after update of status on public.project_members
for each row
execute function public.notify_project_invitation_response();


-- ============================================================
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.notify_project_invitation()
from public, anon, authenticated;

revoke execute
on function public.notify_project_invitation_response()
from public, anon, authenticated;


-- ============================================================
-- 4. INVITATION LOOKUP INDEX
-- ============================================================

create index if not exists project_members_profile_status_idx
on public.project_members (
    profile_id,
    status
);


-- ============================================================
-- END OF MIGRATION 019
-- ============================================================
