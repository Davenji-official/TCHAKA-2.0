-- ============================================================
-- TCHAKA 2.0
-- Migration 020
-- Funding notifications
-- ============================================================


-- ============================================================
-- 1. FUNDING CONTRIBUTION CREATED
-- ============================================================

create or replace function public.notify_funding_contribution_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_creator_id uuid;
    v_project_title text;
    v_contributor_name text;
begin

    -- Only notify for newly created pending contributions.
    if new.status <> 'pending' then
        return new;
    end if;

    select
        p.creator_id,
        p.title
    into
        v_creator_id,
        v_project_title
    from public.funding_campaigns fc
    join public.projects p
        on p.id = fc.project_id
    where fc.id = new.campaign_id;

    if v_creator_id is null
       or v_creator_id = new.contributor_id then
        return new;
    end if;

    select coalesce(
        nullif(p.full_name, ''),
        nullif(p.username, ''),
        'Un utilisateur'
    )
    into v_contributor_name
    from public.profiles p
    where p.id = new.contributor_id;

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
        new.contributor_id,
        'funding',
        'Nouvelle contribution',
        v_contributor_name
            || ' a effectué une contribution de '
            || new.amount::text
            || ' '
            || new.currency
            || ' pour votre projet « '
            || coalesce(v_project_title, 'Projet')
            || ' ». La contribution est en attente de confirmation.',
        'funding_campaign',
        new.campaign_id
    );

    return new;
end;
$$;


drop trigger if exists funding_contribution_created_notification
on public.funding_contributions;

create trigger funding_contribution_created_notification
after insert on public.funding_contributions
for each row
execute function public.notify_funding_contribution_created();


-- ============================================================
-- 2. FUNDING STATUS CHANGE NOTIFICATION
--
-- This function is intended for trusted server-side updates.
-- The client currently has no UPDATE policy on contributions.
-- ============================================================

create or replace function public.notify_funding_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_creator_id uuid;
    v_project_title text;
    v_status_label text;
    v_notification_title text;
begin

    -- Ignore unchanged statuses.
    if old.status = new.status then
        return new;
    end if;

    select
        p.creator_id,
        p.title
    into
        v_project_creator_id,
        v_project_title
    from public.funding_campaigns fc
    join public.projects p
        on p.id = fc.project_id
    where fc.id = new.campaign_id;

    if v_project_creator_id is null then
        return new;
    end if;


    -- --------------------------------------------------------
    -- Status labels
    -- --------------------------------------------------------

    case new.status

        when 'processing' then
            v_status_label := 'est en cours de traitement';
            v_notification_title := 'Contribution en traitement';

        when 'completed' then
            v_status_label := 'a été confirmée';
            v_notification_title := 'Contribution confirmée';

        when 'failed' then
            v_status_label := 'a échoué';
            v_notification_title := 'Contribution échouée';

        when 'refunded' then
            v_status_label := 'a été remboursée';
            v_notification_title := 'Contribution remboursée';

        when 'cancelled' then
            v_status_label := 'a été annulée';
            v_notification_title := 'Contribution annulée';

        else
            return new;

    end case;


    -- --------------------------------------------------------
    -- Notify contributor
    -- --------------------------------------------------------

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
        new.contributor_id,
        null,
        'funding',
        v_notification_title,
        'Votre contribution de '
            || new.amount::text
            || ' '
            || new.currency
            || ' pour « '
            || coalesce(v_project_title, 'Projet')
            || ' » '
            || v_status_label
            || '.',
        'funding_contribution',
        new.id
    );


    -- --------------------------------------------------------
    -- Notify project owner for important final states.
    -- Avoid duplicate notification for the contributor when
    -- contributor and owner are the same account.
    -- --------------------------------------------------------

    if new.status in (
        'completed',
        'failed',
        'refunded'
    )
    and v_project_creator_id <> new.contributor_id then

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
            v_project_creator_id,
            new.contributor_id,
            'funding',
            v_notification_title,
            'La contribution de '
                || new.amount::text
                || ' '
                || new.currency
                || ' pour « '
                || coalesce(v_project_title, 'Projet')
                || ' » '
                || v_status_label
                || '.',
            'funding_contribution',
            new.id
        );

    end if;

    return new;
end;
$$;


drop trigger if exists funding_status_change_notification
on public.funding_contributions;

create trigger funding_status_change_notification
after update of status on public.funding_contributions
for each row
execute function public.notify_funding_status_change();


-- ============================================================
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.notify_funding_contribution_created()
from public, anon, authenticated;

revoke execute
on function public.notify_funding_status_change()
from public, anon, authenticated;


-- ============================================================
-- 4. FUNDING NOTIFICATION INDEX
-- ============================================================

create index if not exists notifications_funding_entity_idx
on public.notifications (
    entity_type,
    entity_id
);


-- ============================================================
-- END OF MIGRATION 020
-- ============================================================
