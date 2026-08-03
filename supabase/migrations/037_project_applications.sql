-- ============================================================
-- TCHAKA 2.0
-- Migration 037
-- Project applications
-- ============================================================


-- ============================================================
-- 1. PROJECT APPLICATIONS
-- ============================================================

create table if not exists public.project_applications (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    applicant_id uuid not null
        references public.profiles(id)
        on delete cascade,

    proposed_role text,

    cover_message text,

    status text not null default 'pending',

    reviewed_by uuid
        references public.profiles(id)
        on delete set null,

    reviewed_at timestamptz,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    constraint project_applications_status_check
        check (
            status in (
                'pending',
                'accepted',
                'rejected',
                'withdrawn'
            )
        ),

    constraint project_applications_role_length
        check (
            proposed_role is null
            or char_length(proposed_role) between 2 and 100
        ),

    constraint project_applications_message_length
        check (
            cover_message is null
            or char_length(cover_message) between 1 and 5000
        ),

    constraint project_applications_unique_applicant
        unique (project_id, applicant_id)
);


-- ============================================================
-- 2. INDEXES
-- ============================================================

create index if not exists project_applications_project_idx
on public.project_applications (
    project_id
);

create index if not exists project_applications_applicant_idx
on public.project_applications (
    applicant_id
);

create index if not exists project_applications_status_idx
on public.project_applications (
    status
);

create index if not exists project_applications_project_status_idx
on public.project_applications (
    project_id,
    status
);

create index if not exists project_applications_created_at_idx
on public.project_applications (
    created_at desc
);


-- ============================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================

alter table public.project_applications
enable row level security;


-- ============================================================
-- 4. APPLICANT READ
-- ============================================================

create policy "project_applications_select_own"
on public.project_applications
for select
to authenticated
using (
    applicant_id = (select auth.uid())
);


-- ============================================================
-- 5. PROJECT OWNER READ
-- ============================================================

create policy "project_applications_select_project_owner"
on public.project_applications
for select
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_applications.project_id
          and p.creator_id = (select auth.uid())
    )
);


-- ============================================================
-- 6. CREATE APPLICATION
-- ============================================================

create policy "project_applications_insert_own"
on public.project_applications
for insert
to authenticated
with check (
    applicant_id = (select auth.uid())

    and exists (
        select 1
        from public.projects p
        where p.id = project_applications.project_id
          and p.status = 'published'
          and p.visibility = 'public'
          and p.creator_id <> (select auth.uid())
    )

    and not exists (
        select 1
        from public.project_members pm
        where pm.project_id = project_applications.project_id
          and pm.profile_id = (select auth.uid())
          and pm.status in ('pending', 'active')
    )
);


-- ============================================================
-- 7. APPLICANT WITHDRAW
-- ============================================================

create policy "project_applications_update_own"
on public.project_applications
for update
to authenticated
using (
    applicant_id = (select auth.uid())
)
with check (
    applicant_id = (select auth.uid())
    and status = 'withdrawn'
);


-- ============================================================
-- 8. PROJECT OWNER REVIEW
-- ============================================================

create policy "project_applications_review_owner"
on public.project_applications
for update
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_applications.project_id
          and p.creator_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.projects p
        where p.id = project_applications.project_id
          and p.creator_id = (select auth.uid())
    )

    and status in (
        'accepted',
        'rejected'
    )

    and reviewed_by = (select auth.uid())
);


-- ============================================================
-- 9. DELETE OWN APPLICATION
-- ============================================================

create policy "project_applications_delete_own"
on public.project_applications
for delete
to authenticated
using (
    applicant_id = (select auth.uid())
);


-- ============================================================
-- 10. UPDATE TIMESTAMP
-- ============================================================

create or replace function public.set_project_application_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;


drop trigger if exists project_applications_updated_at
on public.project_applications;


create trigger project_applications_updated_at
before update on public.project_applications
for each row
execute function public.set_project_application_updated_at();


-- ============================================================
-- 11. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.set_project_application_updated_at()
from public, anon;

grant execute
on function public.set_project_application_updated_at()
to authenticated;


-- ============================================================
-- END OF MIGRATION 037
-- ============================================================
