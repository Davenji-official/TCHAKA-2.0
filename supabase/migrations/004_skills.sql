-- ============================================================
-- TCHAKA 2.0
-- Migration 004
-- Skills
-- ============================================================

create table if not exists public.skills (
    id uuid primary key default gen_random_uuid(),

    name text not null unique,
    slug text not null unique,
    category text,

    created_at timestamptz not null default now()
);

create table if not exists public.user_skills (
    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    skill_id uuid not null
        references public.skills(id)
        on delete cascade,

    proficiency smallint,

    created_at timestamptz not null default now(),

    primary key (profile_id, skill_id),

    constraint user_skills_proficiency_check
        check (
            proficiency is null
            or proficiency between 1 and 5
        )
);

create index if not exists user_skills_profile_id_idx
    on public.user_skills (profile_id);

create index if not exists user_skills_skill_id_idx
    on public.user_skills (skill_id);

alter table public.skills enable row level security;
alter table public.user_skills enable row level security;
