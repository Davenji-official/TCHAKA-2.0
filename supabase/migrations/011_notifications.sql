-- ============================================================
-- TCHAKA 2.0
-- Migration 011
-- Notifications
-- ============================================================

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),

    recipient_id uuid not null
        references public.profiles(id)
        on delete cascade,

    actor_id uuid
        references public.profiles(id)
        on delete set null,

    type text not null,

    title text not null,

    body text,

    entity_type text,

    entity_id uuid,

    is_read boolean not null default false,

    created_at timestamptz not null default now(),

    read_at timestamptz,

    constraint notifications_type_check
        check (
            type in (
                'like',
                'comment',
                'follow',
                'message',
                'funding',
                'project_update',
                'team_invite',
                'verification',
                'system'
            )
        )
);

create index if not exists notifications_recipient_idx
    on public.notifications (recipient_id);

create index if not exists notifications_unread_idx
    on public.notifications (recipient_id, is_read);

create index if not exists notifications_created_at_idx
    on public.notifications (created_at desc);

alter table public.notifications enable row level security;


-- ============================================================
-- SELECT
-- ============================================================

create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (
    auth.uid() = recipient_id
);


-- ============================================================
-- UPDATE
-- ============================================================

create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (
    auth.uid() = recipient_id
)
with check (
    auth.uid() = recipient_id
);


-- ============================================================
-- DELETE
-- ============================================================

create policy "notifications_delete_own"
on public.notifications
for delete
to authenticated
using (
    auth.uid() = recipient_id
);
