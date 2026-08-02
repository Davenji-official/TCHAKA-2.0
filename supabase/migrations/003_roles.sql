-- ============================================================
-- TCHAKA 2.0
-- Migration 003
-- Roles
-- ============================================================

create table if not exists public.roles (
    id uuid primary key default gen_random_uuid(),

    name text not null unique,
    slug text not null unique,
    description text,

    created_at timestamptz not null default now()
);

create table if not exists public.profile_roles (
    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    role_id uuid not null
        references public.roles(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (profile_id, role_id)
);

create index if not exists profile_roles_profile_id_idx
    on public.profile_roles (profile_id);

create index if not exists profile_roles_role_id_idx
    on public.profile_roles (role_id);

alter table public.roles enable row level security;
alter table public.profile_roles enable row level security;

insert into public.roles (name, slug, description)
values
    (
        'Creator',
        'creator',
        'Creates projects, ideas, products or initiatives.'
    ),
    (
        'Solutioner',
        'solutioner',
        'Contributes skills, expertise or solutions to projects.'
    ),
    (
        'Investor',
        'investor',
        'Provides financial support to eligible projects.'
    ),
    (
        'Mentor',
        'mentor',
        'Provides guidance, expertise and mentorship.'
    ),
    (
        'Organization',
        'organization',
        'Represents an organization, company, institution or association.'
    )
on conflict (slug) do nothing;
