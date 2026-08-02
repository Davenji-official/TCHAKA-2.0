-- ============================================================
-- TCHAKA 2.0
-- Migration 012
-- Messaging
-- ============================================================


-- ============================================================
-- CONVERSATIONS
-- ============================================================

create table if not exists public.conversations (
    id uuid primary key default gen_random_uuid(),

    type text not null default 'direct',

    title text,

    created_by uuid not null
        references public.profiles(id)
        on delete cascade,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint conversations_type_check
        check (
            type in (
                'direct',
                'group'
            )
        ),

    constraint conversations_title_check
        check (
            type = 'direct'
            or title is not null
        )
);


-- ============================================================
-- CONVERSATION MEMBERS
-- ============================================================

create table if not exists public.conversation_members (
    conversation_id uuid not null
        references public.conversations(id)
        on delete cascade,

    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    joined_at timestamptz not null default now(),

    last_read_at timestamptz,

    is_muted boolean not null default false,

    primary key (conversation_id, profile_id)
);


-- ============================================================
-- MESSAGES
-- ============================================================

create table if not exists public.messages (
    id uuid primary key default gen_random_uuid(),

    conversation_id uuid not null
        references public.conversations(id)
        on delete cascade,

    sender_id uuid not null
        references public.profiles(id)
        on delete cascade,

    reply_to_id uuid
        references public.messages(id)
        on delete set null,

    content text,

    message_type text not null default 'text',

    created_at timestamptz not null default now(),

    edited_at timestamptz,

    deleted_at timestamptz,

    constraint messages_type_check
        check (
            message_type in (
                'text',
                'image',
                'video',
                'file',
                'system'
            )
        ),

    constraint messages_content_check
        check (
            content is not null
            or message_type <> 'text'
        )
);


-- ============================================================
-- MESSAGE ATTACHMENTS
-- ============================================================

create table if not exists public.message_attachments (
    id uuid primary key default gen_random_uuid(),

    message_id uuid not null
        references public.messages(id)
        on delete cascade,

    storage_path text not null,

    file_name text,

    mime_type text,

    file_size_bytes bigint,

    created_at timestamptz not null default now(),

    constraint message_attachments_size_check
        check (
            file_size_bytes is null
            or file_size_bytes >= 0
        )
);


-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists conversations_created_by_idx
    on public.conversations (created_by);

create index if not exists conversations_updated_at_idx
    on public.conversations (updated_at desc);

create index if not exists conversation_members_profile_idx
    on public.conversation_members (profile_id);

create index if not exists messages_conversation_idx
    on public.messages (conversation_id);

create index if not exists messages_sender_idx
    on public.messages (sender_id);

create index if not exists messages_created_at_idx
    on public.messages (created_at desc);

create index if not exists message_attachments_message_idx
    on public.message_attachments (message_id);


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_attachments enable row level security;


-- ============================================================
-- CONVERSATIONS
-- ============================================================

create policy "conversations_select_member"
on public.conversations
for select
to authenticated
using (
    exists (
        select 1
        from public.conversation_members cm
        where cm.conversation_id = conversations.id
        and cm.profile_id = auth.uid()
    )
);


create policy "conversations_insert_authenticated"
on public.conversations
for insert
to authenticated
with check (
    auth.uid() = created_by
);


create policy "conversations_update_creator"
on public.conversations
for update
to authenticated
using (
    auth.uid() = created_by
)
with check (
    auth.uid() = created_by
);


-- ============================================================
-- CONVERSATION MEMBERS
-- ============================================================

create policy "conversation_members_select_member"
on public.conversation_members
for select
to authenticated
using (
    exists (
        select 1
        from public.conversation_members own_membership
        where own_membership.conversation_id =
            conversation_members.conversation_id
        and own_membership.profile_id = auth.uid()
    )
);


create policy "conversation_members_insert_creator"
on public.conversation_members
for insert
to authenticated
with check (
    exists (
        select 1
        from public.conversations c
        where c.id = conversation_members.conversation_id
        and c.created_by = auth.uid()
    )
);


create policy "conversation_members_delete_self"
on public.conversation_members
for delete
to authenticated
using (
    auth.uid() = profile_id
);


-- ============================================================
-- MESSAGES
-- ============================================================

create policy "messages_select_member"
on public.messages
for select
to authenticated
using (
    exists (
        select 1
        from public.conversation_members cm
        where cm.conversation_id = messages.conversation_id
        and cm.profile_id = auth.uid()
    )
);


create policy "messages_insert_member"
on public.messages
for insert
to authenticated
with check (
    auth.uid() = sender_id
    and exists (
        select 1
        from public.conversation_members cm
        where cm.conversation_id = messages.conversation_id
        and cm.profile_id = auth.uid()
    )
);


create policy "messages_update_own"
on public.messages
for update
to authenticated
using (
    auth.uid() = sender_id
)
with check (
    auth.uid() = sender_id
);


create policy "messages_delete_own"
on public.messages
for delete
to authenticated
using (
    auth.uid() = sender_id
);


-- ============================================================
-- MESSAGE ATTACHMENTS
-- ============================================================

create policy "message_attachments_select_member"
on public.message_attachments
for select
to authenticated
using (
    exists (
        select 1
        from public.messages m
        join public.conversation_members cm
            on cm.conversation_id = m.conversation_id
        where m.id = message_attachments.message_id
        and cm.profile_id = auth.uid()
    )
);


create policy "message_attachments_insert_own_message"
on public.message_attachments
for insert
to authenticated
with check (
    exists (
        select 1
        from public.messages m
        where m.id = message_attachments.message_id
        and m.sender_id = auth.uid()
    )
);


create policy "message_attachments_delete_own_message"
on public.message_attachments
for delete
to authenticated
using (
    exists (
        select 1
        from public.messages m
        where m.id = message_attachments.message_id
        and m.sender_id = auth.uid()
    )
);
