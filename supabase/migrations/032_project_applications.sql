-- ============================================================
-- TCHAKA 2.0
-- Migration 032
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
                'reviewing',
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

    constraint project_applications_project_applicant_unique
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

create index if not exists project_applications_applicant_status_idx
on public.project_applications (
    applicant_id,
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
    public.is_project_owner(
        project_applications.project_id,
        (select auth.uid())
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

    and not public.is_project_owner(
        project_applications.project_id,
        (select auth.uid())
    )

    and exists (
        select 1
        from public.projects p
        where p.id = project_applications.project_id
          and p.status = 'published'
          and p.visibility = 'public'
    )
);


-- ============================================================
-- 7. APPLICANT WITHDRAW
-- ============================================================

create policy "project_applications_update_own_withdraw"
on public.project_applications
for update
to authenticated
using (
    applicant_id = (select auth.uid())
    and status in (
        'pending',
        'reviewing'
    )
)
with check (
    applicant_id = (select auth.uid())
    and status = 'withdrawn'
);


-- ============================================================
-- 8. PROJECT OWNER REVIEW
-- ============================================================

create policy "project_applications_update_owner_review"
on public.project_applications
for update
to authenticated
using (
    public.is_project_owner(
        project_applications.project_id,
        (select auth.uid())
    )
)
with check (
    public.is_project_owner(
        project_applications.project_id,
        (select auth.uid())
    )

    and status in (
        'pending',
        'reviewing',
        'accepted',
        'rejected'
    )

    and (
        reviewed_by = (select auth.uid())
        or reviewed_by is null
    )
);


-- ============================================================
-- 9. DELETE OWN WITHDRAWN APPLICATION
-- ============================================================

create policy "project_applications_delete_own_withdrawn"
on public.project_applications
for delete
to authenticated
using (
    applicant_id = (select auth.uid())
    and status = 'withdrawn'
);


-- ============================================================
-- 10. FUNCTION TO REVIEW APPLICATION
-- ============================================================

create or replace function public.review_project_application(
    p_application_id uuid,
    p_status text
)
returns public.project_applications
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_application public.project_applications;
begin

    if p_status not in (
        'pending',
        'reviewing',
        'accepted',
        'rejected'
    ) then
        raise exception 'Invalid application status';
    end if;

    update public.project_applications
    set
        status = p_status,
        reviewed_by = (select auth.uid()),
        reviewed_at = case
            when p_status in ('accepted', 'rejected')
            then now()
            else reviewed_at
        end,
        updated_at = now()
    where id = p_application_id
      and public.is_project_owner(
          project_id,
          (select auth.uid())
      )
    returning *
    into v_application;

    if v_application.id is null then
        raise exception 'Application not found or unauthorized';
    end if;

    return v_application;
end;
$$;


-- ============================================================
-- 11. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.review_project_application(
    uuid,
    text
)
from public, anon;

grant execute
on function public.review_project_application(
    uuid,
    text
)
to authenticated;


-- ============================================================
-- 12. END
-- ============================================================
