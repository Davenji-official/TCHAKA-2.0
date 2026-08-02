-- ============================================================
-- TCHAKA 2.0
-- Migration 010
-- Project media
-- ============================================================

create table if not exists public.project_media (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    uploaded_by uuid not null
        references public.profiles(id)
        on delete cascade,

    storage_path text not null,

    media_type text not null,

    mime_type text,

    file_size_bytes bigint,

    width integer,
    height integer,

    duration_seconds numeric(12, 3),

    sort_order integer not null default 0,

    created_at timestamptz not null default now(),

    constraint project_media_type_check
        check (
            media_type in (
                'image',
                'video'
            )
        ),

    constraint project_media_size_check
        check (
            file_size_bytes is null
            or file_size_bytes >= 0
        ),

    constraint project_media_dimensions_check
        check (
            (width is null or width > 0)
            and
            (height is null or height > 0)
        ),

    constraint project_media_sort_order_check
        check (sort_order >= 0)
);

create index if not exists project_media_project_id_idx
    on public.project_media (project_id);

create index if not exists project_media_uploaded_by_idx
    on public.project_media (uploaded_by);

create index if not exists project_media_project_sort_idx
    on public.project_media (project_id, sort_order);

alter table public.project_media enable row level security;


-- ============================================================
-- READ
-- ============================================================

create policy "project_media_select_visible"
on public.project_media
for select
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_media.project_id
        and (
            (
                p.visibility = 'public'
                and p.status = 'published'
            )
            or p.creator_id = auth.uid()
        )
    )
);


-- ============================================================
-- INSERT
-- ============================================================

create policy "project_media_insert_project_owner"
on public.project_media
for insert
to authenticated
with check (
    auth.uid() = uploaded_by
    and exists (
        select 1
        from public.projects p
        where p.id = project_media.project_id
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- UPDATE
-- ============================================================

create policy "project_media_update_project_owner"
on public.project_media
for update
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_media.project_id
        and p.creator_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.projects p
        where p.id = project_media.project_id
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- DELETE
-- ============================================================

create policy "project_media_delete_project_owner"
on public.project_media
for delete
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_media.project_id
        and p.creator_id = auth.uid()
    )
);
