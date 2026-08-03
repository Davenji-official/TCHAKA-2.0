-- ============================================================
-- TCHAKA 2.0
-- Migration 044
-- Secure project media storage
-- ============================================================

-- ============================================================
-- 1. PROJECT MEDIA STORAGE BUCKET
-- ============================================================

insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'project-media',
    'project-media',
    false,
    10485760,
    array[
        'image/jpeg',
        'image/png',
        'image/webp'
    ]
)
on conflict (id) do update
set
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array[
        'image/jpeg',
        'image/png',
        'image/webp'
    ];


-- ============================================================
-- STORAGE PATH
--
-- Every project image must follow:
--
-- project-media/
--   {user_id}/
--     {project_id}/
--       {filename}
--
-- Example:
--
-- project-media/
--   00000000-0000-0000-0000-000000000000/
--     11111111-1111-1111-1111-111111111111/
--       cover.webp
--
-- ============================================================


-- ============================================================
-- 2. INSERT
-- ============================================================

drop policy if exists "project_media_storage_insert"
on storage.objects;

create policy "project_media_storage_insert"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'project-media'

    and split_part(name, '/', 1) = auth.uid()::text

    and exists (
        select 1
        from public.projects p
        where p.id::text = split_part(name, '/', 2)
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- 3. SELECT
--
-- Owner can read their own project media.
--
-- Everyone authenticated can read media belonging to a
-- published public project.
-- ============================================================

drop policy if exists "project_media_storage_select"
on storage.objects;

create policy "project_media_storage_select"
on storage.objects
for select
to authenticated
using (
    bucket_id = 'project-media'

    and exists (
        select 1
        from public.projects p
        where p.id::text = split_part(name, '/', 2)
        and (
            p.creator_id = auth.uid()
            or (
                p.visibility = 'public'
                and p.status = 'published'
            )
        )
    )
);


-- ============================================================
-- 4. UPDATE
-- ============================================================

drop policy if exists "project_media_storage_update"
on storage.objects;

create policy "project_media_storage_update"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'project-media'

    and split_part(name, '/', 1) = auth.uid()::text

    and exists (
        select 1
        from public.projects p
        where p.id::text = split_part(name, '/', 2)
        and p.creator_id = auth.uid()
    )
)
with check (
    bucket_id = 'project-media'

    and split_part(name, '/', 1) = auth.uid()::text

    and exists (
        select 1
        from public.projects p
        where p.id::text = split_part(name, '/', 2)
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- 5. DELETE
-- ============================================================

drop policy if exists "project_media_storage_delete"
on storage.objects;

create policy "project_media_storage_delete"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'project-media'

    and split_part(name, '/', 1) = auth.uid()::text

    and exists (
        select 1
        from public.projects p
        where p.id::text = split_part(name, '/', 2)
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- 6. END
-- ============================================================
