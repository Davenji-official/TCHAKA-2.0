-- ============================================================
-- TCHAKA 2.0
-- Migration 018
-- Automatic social notifications
-- ============================================================

-- ============================================================
-- 1. PROJECT LIKE NOTIFICATION
-- ============================================================

create or replace function public.notify_project_like()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_creator_id uuid;
    v_actor_name text;
begin

    select p.creator_id
    into v_creator_id
    from public.projects p
    where p.id = new.project_id;

    -- Do not notify a user about their own action.
    if v_creator_id is null
       or v_creator_id = new.profile_id then
        return new;
    end if;

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_actor_name
    from public.profiles p
    where p.id = new.profile_id;

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
        v_creator_id,
        new.profile_id,
        'like',
        'Nouveau j’aime',
        v_actor_name || ' a aimé votre projet.',
        'project',
        new.project_id
    );

    return new;
end;
$$;


drop trigger if exists project_like_notification
on public.project_likes;

create trigger project_like_notification
after insert on public.project_likes
for each row
execute function public.notify_project_like();


-- ============================================================
-- 2. FOLLOW NOTIFICATION
-- ============================================================

create or replace function public.notify_new_follow()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_name text;
begin

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_actor_name
    from public.profiles p
    where p.id = new.follower_id;

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
        new.following_id,
        new.follower_id,
        'follow',
        'Nouvel abonné',
        v_actor_name || ' vous suit maintenant.',
        'profile',
        new.follower_id
    );

    return new;
end;
$$;


drop trigger if exists follow_notification
on public.follows;

create trigger follow_notification
after insert on public.follows
for each row
execute function public.notify_new_follow();


-- ============================================================
-- 3. COMMENT NOTIFICATION
-- ============================================================

create or replace function public.notify_new_comment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_creator_id uuid;
    v_actor_name text;
begin

    select p.creator_id
    into v_creator_id
    from public.projects p
    where p.id = new.project_id;

    if v_creator_id is null
       or v_creator_id = new.profile_id then
        return new;
    end if;

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_actor_name
    from public.profiles p
    where p.id = new.profile_id;

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
        v_creator_id,
        new.profile_id,
        'comment',
        'Nouveau commentaire',
        v_actor_name || ' a commenté votre projet.',
        'project',
        new.project_id
    );

    return new;
end;
$$;


drop trigger if exists comment_notification
on public.comments;

create trigger comment_notification
after insert on public.comments
for each row
execute function public.notify_new_comment();


-- ============================================================
-- 4. FUNCTION PRIVILEGES
--
-- These functions are triggered internally.
-- They must not be callable directly by anonymous clients.
-- ============================================================

revoke execute
on function public.notify_project_like()
from public, anon, authenticated;

revoke execute
on function public.notify_new_follow()
from public, anon, authenticated;

revoke execute
on function public.notify_new_comment()
from public, anon, authenticated;


-- ============================================================
-- 5. INDEX FOR NOTIFICATION LOOKUPS
-- ============================================================

create index if not exists notifications_recipient_created_idx
on public.notifications (
    recipient_id,
    created_at desc
);


-- ============================================================
-- END OF MIGRATION 018
-- ============================================================
