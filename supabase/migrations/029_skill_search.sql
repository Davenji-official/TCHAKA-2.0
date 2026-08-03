-- ============================================================
-- TCHAKA 2.0
-- Migration 029
-- Skill-based search
-- ============================================================


-- ============================================================
-- 1. SEARCH USERS BY SKILL
-- ============================================================

create or replace function public.search_profiles_by_skill(
    p_skill_slug text,
    p_country text default null,
    p_min_proficiency smallint default null,
    p_limit integer default 20,
    p_offset integer default 0
)
returns table (
    profile_id uuid,
    username text,
    full_name text,
    avatar_url text,
    bio text,
    country text,
    city text,
    is_verified boolean,
    skill_id uuid,
    skill_name text,
    skill_slug text,
    skill_category text,
    proficiency smallint,
    relevance real
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id as profile_id,
        p.username,
        p.full_name,
        p.avatar_url,
        p.bio,
        p.country,
        p.city,
        p.is_verified,

        s.id as skill_id,
        s.name as skill_name,
        s.slug as skill_slug,
        s.category as skill_category,

        us.proficiency,

        (
            case
                when us.proficiency is null then 0.5
                else us.proficiency::real / 5.0
            end
        ) as relevance

    from public.user_skills us

    join public.profiles p
        on p.id = us.profile_id

    join public.skills s
        on s.id = us.skill_id

    where
        lower(s.slug) = lower(trim(p_skill_slug))

        and (
            nullif(trim(p_country), '') is null
            or lower(coalesce(p.country, ''))
                = lower(trim(p_country))
        )

        and (
            p_min_proficiency is null
            or us.proficiency >= p_min_proficiency
        )

    order by
        relevance desc,
        p.is_verified desc,
        p.created_at desc

    limit least(
        greatest(coalesce(p_limit, 20), 1),
        100
    )

    offset greatest(
        coalesce(p_offset, 0),
        0
    );
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.search_profiles_by_skill(
    text,
    text,
    smallint,
    integer,
    integer
)
from public, anon;

grant execute
on function public.search_profiles_by_skill(
    text,
    text,
    smallint,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 3. SEARCH PROJECTS BY SKILL
-- ============================================================

create or replace function public.search_projects_by_skill(
    p_skill_slug text,
    p_country text default null,
    p_required_only boolean default false,
    p_limit integer default 20,
    p_offset integer default 0
)
returns table (
    project_id uuid,
    creator_id uuid,
    title text,
    slug text,
    description text,
    category text,
    country text,
    city text,
    cover_image_url text,
    status text,
    funding_goal numeric,
    funding_currency text,
    skill_id uuid,
    skill_name text,
    skill_slug text,
    skill_category text,
    required boolean,
    relevance real
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id as project_id,
        p.creator_id,
        p.title,
        p.slug,
        p.description,
        p.category,
        p.country,
        p.city,
        p.cover_image_url,
        p.status,
        p.funding_goal,
        p.funding_currency,

        s.id as skill_id,
        s.name as skill_name,
        s.slug as skill_slug,
        s.category as skill_category,

        ps.required,

        (
            case
                when ps.required = true then 1.0
                else 0.75
            end
        )::real as relevance

    from public.project_skills ps

    join public.projects p
        on p.id = ps.project_id

    join public.skills s
        on s.id = ps.skill_id

    where
        lower(s.slug) = lower(trim(p_skill_slug))

        and p.visibility = 'public'
        and p.status = 'published'

        and (
            nullif(trim(p_country), '') is null
            or lower(coalesce(p.country, ''))
                = lower(trim(p_country))
        )

        and (
            coalesce(p_required_only, false) = false
            or ps.required = true
        )

    order by
        relevance desc,
        p.created_at desc

    limit least(
        greatest(coalesce(p_limit, 20), 1),
        100
    )

    offset greatest(
        coalesce(p_offset, 0),
        0
    );
$$;


-- ============================================================
-- 4. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.search_projects_by_skill(
    text,
    text,
    boolean,
    integer,
    integer
)
from public, anon;

grant execute
on function public.search_projects_by_skill(
    text,
    text,
    boolean,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 5. PERFORMANCE INDEXES
-- ============================================================

create index if not exists skills_slug_lower_idx
on public.skills (
    lower(slug)
);

create index if not exists user_skills_skill_proficiency_idx
on public.user_skills (
    skill_id,
    proficiency desc
);

create index if not exists project_skills_skill_required_idx
on public.project_skills (
    skill_id,
    required
);


-- ============================================================
-- 6. INPUT VALIDATION
-- ============================================================

create or replace function public.validate_skill_search_proficiency(
    p_min_proficiency smallint
)
returns boolean
language sql
immutable
set search_path = ''
as $$
    select
        p_min_proficiency is null
        or p_min_proficiency between 1 and 5;
$$;


-- ============================================================
-- 7. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.validate_skill_search_proficiency(smallint)
from public, anon;

grant execute
on function public.validate_skill_search_proficiency(smallint)
to authenticated;


-- ============================================================
-- END OF MIGRATION 029
-- ============================================================
