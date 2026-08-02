-- ============================================================
-- TCHAKA 2.0
-- Migration 007
-- Core Row Level Security
-- ============================================================

-- ============================================================
-- PROFILES
-- ============================================================

create policy "profiles_select_public"
on public.profiles
for select
using (true);

create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "profiles_delete_own"
on public.profiles
for delete
using (auth.uid() = id);


-- ============================================================
-- ROLES
-- ============================================================

create policy "roles_select_authenticated"
on public.roles
for select
to authenticated
using (true);


-- ============================================================
-- PROFILE ROLES
-- ============================================================

create policy "profile_roles_select"
on public.profile_roles
for select
to authenticated
using (true);

create policy "profile_roles_insert_own"
on public.profile_roles
for insert
to authenticated
with check (
    auth.uid() = profile_id
);

create policy "profile_roles_delete_own"
on public.profile_roles
for delete
to authenticated
using (
    auth.uid() = profile_id
);


-- ============================================================
-- SKILLS
-- ============================================================

create policy "skills_select_authenticated"
on public.skills
for select
to authenticated
using (true);


-- ============================================================
-- USER SKILLS
-- ============================================================

create policy "user_skills_select"
on public.user_skills
for select
to authenticated
using (true);

create policy "user_skills_insert_own"
on public.user_skills
for insert
to authenticated
with check (
    auth.uid() = profile_id
);

create policy "user_skills_update_own"
on public.user_skills
for update
to authenticated
using (
    auth.uid() = profile_id
)
with check (
    auth.uid() = profile_id
);

create policy "user_skills_delete_own"
on public.user_skills
for delete
to authenticated
using (
    auth.uid() = profile_id
);


-- ============================================================
-- PROJECTS
-- ============================================================

create policy "projects_select_public"
on public.projects
for select
using (
    visibility = 'public'
    and status = 'published'
);

create policy "projects_select_own"
on public.projects
for select
to authenticated
using (
    auth.uid() = creator_id
);

create policy "projects_insert_own"
on public.projects
for insert
to authenticated
with check (
    auth.uid() = creator_id
);

create policy "projects_update_own"
on public.projects
for update
to authenticated
using (
    auth.uid() = creator_id
)
with check (
    auth.uid() = creator_id
);

create policy "projects_delete_own"
on public.projects
for delete
to authenticated
using (
    auth.uid() = creator_id
);


-- ============================================================
-- PROJECT SKILLS
-- ============================================================

create policy "project_skills_select"
on public.project_skills
for select
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_skills.project_id
        and (
            (
                p.visibility = 'public'
                and p.status = 'published'
            )
            or p.creator_id = auth.uid()
        )
    )
);

create policy "project_skills_insert_own"
on public.project_skills
for insert
to authenticated
with check (
    exists (
        select 1
        from public.projects p
        where p.id = project_skills.project_id
        and p.creator_id = auth.uid()
    )
);

create policy "project_skills_delete_own"
on public.project_skills
for delete
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_skills.project_id
        and p.creator_id = auth.uid()
    )
);
