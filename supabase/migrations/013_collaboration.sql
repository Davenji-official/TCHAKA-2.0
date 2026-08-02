-- ============================================================
-- TCHAKA 2.0
-- Migration 013
-- Project collaboration
-- ============================================================


-- ============================================================
-- PROJECT MEMBERS
-- ============================================================

create table if not exists public.project_members (
    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    role text not null default 'contributor',

    status text not null default 'pending',

    invited_by uuid
        references public.profiles(id)
        on delete set null,

    joined_at timestamptz,

    created_at timestamptz not null default now(),

    primary key (project_id, profile_id),

    constraint project_members_role_check
        check (
            role in (
                'owner',
                'admin',
                'developer',
                'designer',
                'marketing',
                'mentor',
                'contributor'
            )
        ),

    constraint project_members_status_check
        check (
            status in (
                'pending',
                'active',
                'declined',
                'removed'
            )
        )
);


-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists project_members_profile_idx
    on public.project_members (profile_id);

create index if not exists project_members_project_idx
    on public.project_members (project_id);

create index if not exists project_members_status_idx
    on public.project_members (status);


-- ============================================================
-- RLS
-- ============================================================

alter table public.project_members enable row level security;


-- ============================================================
-- SELECT
-- ============================================================

create policy "project_members_select_project_access"
on public.project_members
for select
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_members.project_id
        and (
            p.creator_id = auth.uid()
            or exists (
                select 1
                from public.project_members pm
                where pm.project_id = p.id
                and pm.profile_id = auth.uid()
                and pm.status = 'active'
            )
        )
    )
);


-- ============================================================
-- INSERT
-- ============================================================

create policy "project_members_insert_project_owner"
on public.project_members
for insert
to authenticated
with check (
    exists (
        select 1
        from public.projects p
        where p.id = project_members.project_id
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- UPDATE
-- ============================================================

create policy "project_members_update_owner"
on public.project_members
for update
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_members.project_id
        and p.creator_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.projects p
        where p.id = project_members.project_id
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- MEMBER ACCEPT / DECLINE
-- ============================================================

create policy "project_members_respond_own_invitation"
on public.project_members
for update
to authenticated
using (
    auth.uid() = profile_id
    and status = 'pending'
)
with check (
    auth.uid() = profile_id
);


-- ============================================================
-- DELETE
-- ============================================================

create policy "project_members_delete_owner"
on public.project_members
for delete
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_members.project_id
        and p.creator_id = auth.uid()
    )
);

create policy "project_members_leave_project"
on public.project_members
for delete
to authenticated
using (
    auth.uid() = profile_id
    and role <> 'owner'
);
