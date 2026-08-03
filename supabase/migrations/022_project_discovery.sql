-- ============================================================
-- TCHAKA 2.0
-- Migration 022
-- Project discovery and search
-- ============================================================

-- ============================================================
-- 1. SEARCH INDEX
-- ============================================================

create index if not exists projects_title_search_idx
on public.projects
using gin (
    to_tsvector(
        'simple',
        coalesce(title, '')
        || ' '
        || coalesce(description, '')
        || ' '
        || coalesce(problem_statement, '')
        || ' '
        || coalesce(solution_description, '')
        || ' '
        || coalesce(category, '')
        || ' '
        || coalesce(country, '')
        || ' '
        || coalesce(city, '')
    )
);


-- ============================================================
-- 2. PROJECT DISCOVERY FUNCTION
-- ============================================================
--
-- Returns only projects that the current user is allowed
-- to discover.
--
-- Public users see published/public projects.
-- Authenticated creators also see their own projects.
--
-- ============================================================

create or replace function public.search_projects(
    search_query text default null,
    filter_category text default null,
    filter_country text default null,
    filter_status text default 'published',
    result_limit integer default 20,
    result_offset integer default 0
)
returns table (
    id uuid,
    creator_id uuid,
    title text,
    slug text,
    description text,
    problem_statement text,
    solution_description text,
    category text,
    country text,
    city text,
    cover_image_url text,
    status text,
    visibility text,
    funding_goal numeric,
    funding_currency text,
    team_size integer,
    created_at timestamptz,
    updated_at timestamptz,
    published_at timestamptz,
    relevance real
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id,
        p.creator_id,
        p.title,
        p.slug,
        p.description,
        p.problem_statement,
        p.solution_description,
        p.category,
        p.country,
        p.city,
        p.cover_image_url,
        p.status,
        p.visibility,
        p.funding_goal,
        p.funding_currency,
        p.team_size,
        p.created_at,
        p.updated_at,
        p.published_at,

        case
            when nullif(trim(search_query), '') is null then 0::real
            else ts_rank(
                to_tsvector(
                    'simple',
                    coalesce(p.title, '')
                    || ' '
                    || coalesce(p.description, '')
                    || ' '
                    || coalesce(p.problem_statement, '')
                    || ' '
                    || coalesce(p.solution_description, '')
                    || ' '
                    || coalesce(p.category, '')
                    || ' '
                    || coalesce(p.country, '')
                    || ' '
                    || coalesce(p.city, '')
                ),
                plainto_tsquery(
                    'simple',
                    trim(search_query)
                )
            )
        end as relevance

    from public.projects p

    where

        -- ----------------------------------------------------
        -- Visibility / authorization
        -- ----------------------------------------------------

        (
            (
                p.visibility = 'public'
                and p.status = 'published'
            )
            or p.creator_id = (select auth.uid())
        )

        -- ----------------------------------------------------
        -- Search
        -- ----------------------------------------------------

        and (
            nullif(trim(search_query), '') is null
            or to_tsvector(
                'simple',
                coalesce(p.title, '')
                || ' '
                || coalesce(p.description, '')
                || ' '
                || coalesce(p.problem_statement, '')
                || ' '
                || coalesce(p.solution_description, '')
                || ' '
                || coalesce(p.category, '')
                || ' '
                || coalesce(p.country, '')
                || ' '
                || coalesce(p.city, '')
            )
            @@ plainto_tsquery(
                'simple',
                trim(search_query)
            )
        )

        -- ----------------------------------------------------
        -- Category
        -- ----------------------------------------------------

        and (
            nullif(trim(filter_category), '') is null
            or lower(p.category) = lower(trim(filter_category))
        )

        -- ----------------------------------------------------
        -- Country
        -- ----------------------------------------------------

        and (
            nullif(trim(filter_country), '') is null
            or lower(p.country) = lower(trim(filter_country))
        )

        -- ----------------------------------------------------
        -- Status
        -- ----------------------------------------------------

        and (
            filter_status is null
            or filter_status = ''
            or p.status = filter_status
        )

    order by
        relevance desc,
        p.published_at desc nulls last,
        p.created_at desc

    limit greatest(1, least(coalesce(result_limit, 20), 100))
    offset greatest(0, coalesce(result_offset, 0));
$$;


-- ============================================================
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.search_projects(
    text,
    text,
    text,
    text,
    integer,
    integer
)
from public, anon;

grant execute
on function public.search_projects(
    text,
    text,
    text,
    text,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 4. DISCOVERY INDEXES
-- ============================================================

create index if not exists projects_category_status_idx
on public.projects (
    category,
    status
);

create index if not exists projects_country_status_idx
on public.projects (
    country,
    status
);

create index if not exists projects_visibility_status_idx
on public.projects (
    visibility,
    status
);

create index if not exists projects_published_at_idx
on public.projects (
    published_at desc
);


-- ============================================================
-- END OF MIGRATION 022
-- ============================================================
