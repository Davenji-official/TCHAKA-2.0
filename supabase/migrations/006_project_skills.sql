-- ============================================================
-- TCHAKA 2.0
-- Migration 006
-- Project skills
-- ============================================================

create table if not exists public.project_skills (
    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    skill_id uuid not null
        references public.skills(id)
        on delete cascade,

    required boolean not null default false,

    created_at timestamptz not null default now(),

    primary key (project_id, skill_id)
);

create index if not exists project_skills_skill_id_idx
    on public.project_skills (skill_id);

create index if not exists project_skills_project_id_idx
    on public.project_skills (project_id);

alter table public.project_skills enable row level security;
