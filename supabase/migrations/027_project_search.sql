-- ============================================================
-- TCHAKA 2.0
-- Migration 027
-- Project search
-- ============================================================


-- ============================================================
-- 1. SEARCH FUNCTION
-- ============================================================

create or replace function public.search_projects(
    p_query text default null,
    p_category text default null,
    p_country text default null,
    p_limit integer default 20,
    p_offset integer default 0
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
            when nullif(trim(p_query), '') is null then 1.0::real

            when lower(p.title) = lower(trim(p_query))
                then 1.0::real

            when lower(p.title) like lower(trim(p_query)) || '%'
                then 0.9::real

            when lower(p.title) like '%' || lower(trim(p_query)) || '%'
                then 0.8::real

            when lower(coalesce(p.description, ''))
                 like '%' || lower(trim(p_query)) || '%'
                then 0.6::real

            when lower(coalesce(p.category, ''))
                 like '%' || lower(trim(p_query)) || '%'
                then 0.5::real

            else 0.4::real
        end as relevance

    from public.projects p

    where
        p.visibility = 'public'
        and p.status = 'published'

        and (
            nullif(trim(p_query), '') is null

            or lower(p.title) like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.description, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.problem_statement, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.solution_description, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.category, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.country, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.city, ''))
                like '%' || lower(trim(p_query)) || '%'
        )

        and (
            nullif(trim(p_category), '') is null
            or lower(p.category) = lower(trim(p_category))
        )

        and (
            nullif(trim(p_country), '') is null
            or lower(p.country) = lower(trim(p_country))
        )

    order by
        relevance desc,
        p.created_at desc

    limit least(greatest(coalesce(p_limit, 20), 1), 100)

    offset greatest(coalesce(p_offset, 0), 0);
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.search_projects(text, text, text, integer, integer)
from public, anon;

grant execute
on function public.search_projects(text, text, text, integer, integer)
to authenticated;


-- ============================================================
-- 3. SEARCH INDEXES
-- ============================================================

create index if not exists projects_title_lower_idx
on public.projects (
    lower(title)
);

create index if not exists projects_category_lower_idx
on public.projects (
    lower(category)
);

create index if not exists projects_country_lower_idx
on public.projects (
    lower(country)
);

create index if not exists projects_city_lower_idx
on public.projects (
    lower(city)
);


-- ============================================================
-- 4. END OF MIGRATION 027
-- ============================================================
