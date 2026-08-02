-- ============================================================
-- TCHAKA 2.0
-- Migration 005
-- Projects
-- ============================================================

create table if not exists public.projects (
    id uuid primary key default gen_random_uuid(),

    creator_id uuid not null
        references public.profiles(id)
        on delete cascade,

    title text not null,
    slug text not null unique,

    description text,
    problem_statement text,
    solution_description text,

    category text,

    country text,
    city text,

    cover_image_url text,

    status text not null default 'draft',
    visibility text not null default 'public',

    funding_goal numeric(14, 2),
    funding_currency text not null default 'USD',

    team_size integer not null default 1,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    published_at timestamptz,

    constraint projects_title_length
        check (char_length(title) between 3 and 150),

    constraint projects_slug_length
        check (char_length(slug) between 3 and 180),

    constraint projects_status_check
        check (
            status in (
                'draft',
                'published',
                'paused',
                'completed',
                'archived'
            )
        ),

    constraint projects_visibility_check
        check (
            visibility in (
                'public',
                'private',
                'unlisted'
            )
        ),

    constraint projects_funding_goal_check
        check (
            funding_goal is null
            or funding_goal >= 0
        ),

    constraint projects_team_size_check
        check (team_size >= 1),

    constraint projects_currency_check
        check (
            funding_currency in (
                'USD',
                'HTG',
                'EUR',
                'CAD'
            )
        )
);

create index if not exists projects_creator_id_idx
    on public.projects (creator_id);

create index if not exists projects_status_idx
    on public.projects (status);

create index if not exists projects_category_idx
    on public.projects (category);

create index if not exists projects_country_idx
    on public.projects (country);

create index if not exists projects_created_at_idx
    on public.projects (created_at desc);

alter table public.projects enable row level security;
