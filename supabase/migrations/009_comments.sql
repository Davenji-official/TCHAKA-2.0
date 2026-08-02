-- ============================================================
-- TCHAKA 2.0
-- Migration 009
-- Comments
-- ============================================================

create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    parent_id uuid
        references public.comments(id)
        on delete cascade,

    content text not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz,

    constraint comments_content_length
        check (
            char_length(content) between 1 and 5000
        )
);

create index if not exists comments_project_id_idx
    on public.comments (project_id);

create index if not exists comments_profile_id_idx
    on public.comments (profile_id);

create index if not exists comments_parent_id_idx
    on public.comments (parent_id);

create index if not exists comments_created_at_idx
    on public.comments (created_at desc);

alter table public.comments enable row level security;


-- ============================================================
-- READ
-- ============================================================

create policy "comments_select_public_projects"
on public.comments
for select
using (
    exists (
        select 1
        from public.projects p
        where p.id = comments.project_id
        and (
            (
                p.visibility = 'public'
                and p.status = 'published'
            )
            or p.creator_id = auth.uid()
            or comments.profile_id = auth.uid()
        )
    )
);


-- ============================================================
-- CREATE
-- ============================================================

create policy "comments_insert_own"
on public.comments
for insert
to authenticated
with check (
    auth.uid() = profile_id
    and exists (
        select 1
        from public.projects p
        where p.id = comments.project_id
        and p.visibility = 'public'
        and p.status = 'published'
    )
);


-- ============================================================
-- UPDATE
-- ============================================================

create policy "comments_update_own"
on public.comments
for update
to authenticated
using (
    auth.uid() = profile_id
)
with check (
    auth.uid() = profile_id
);


-- ============================================================
-- DELETE
-- ============================================================

create policy "comments_delete_own"
on public.comments
for delete
to authenticated
using (
    auth.uid() = profile_id
);
