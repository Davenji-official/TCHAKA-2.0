-- ============================================================
-- TCHAKA 2.0
-- Migration 028
-- Profile search
-- ============================================================


-- ============================================================
-- 1. SEARCH FUNCTION
-- ============================================================

create or replace function public.search_profiles(
    p_query text default null,
    p_country text default null,
    p_city text default null,
    p_verified_only boolean default false,
    p_limit integer default 20,
    p_offset integer default 0
)
returns table (
    id uuid,
    username text,
    full_name text,
    avatar_url text,
    bio text,
    country text,
    city text,
    is_verified boolean,
    is_premium boolean,
    created_at timestamptz,
    relevance real
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id,
        p.username,
        p.full_name,
        p.avatar_url,
        p.bio,
        p.country,
        p.city,
        p.is_verified,
        p.is_premium,
        p.created_at,

        case
            when nullif(trim(p_query), '') is null
                then 1.0::real

            when lower(coalesce(p.username, ''))
                = lower(trim(p_query))
                then 1.0::real

            when lower(coalesce(p.full_name, ''))
                = lower(trim(p_query))
                then 0.98::real

            when lower(coalesce(p.username, ''))
                like lower(trim(p_query)) || '%'
                then 0.9::real

            when lower(coalesce(p.full_name, ''))
                like lower(trim(p_query)) || '%'
                then 0.85::real

            when lower(coalesce(p.username, ''))
                like '%' || lower(trim(p_query)) || '%'
                then 0.75::real

            when lower(coalesce(p.full_name, ''))
                like '%' || lower(trim(p_query)) || '%'
                then 0.7::real

            when lower(coalesce(p.bio, ''))
                like '%' || lower(trim(p_query)) || '%'
                then 0.5::real

            else 0.4::real
        end as relevance

    from public.profiles p

    where

        (
            nullif(trim(p_query), '') is null

            or lower(coalesce(p.username, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.full_name, ''))
                like '%' || lower(trim(p_query)) || '%'

            or lower(coalesce(p.bio, ''))
                like '%' || lower(trim(p_query)) || '%'
        )

        and (
            nullif(trim(p_country), '') is null
            or lower(coalesce(p.country, ''))
                = lower(trim(p_country))
        )

        and (
            nullif(trim(p_city), '') is null
            or lower(coalesce(p.city, ''))
                = lower(trim(p_city))
        )

        and (
            coalesce(p_verified_only, false) = false
            or p.is_verified = true
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
on function public.search_profiles(
    text,
    text,
    text,
    boolean,
    integer,
    integer
)
from public, anon;

grant execute
on function public.search_profiles(
    text,
    text,
    text,
    boolean,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 3. SEARCH INDEXES
-- ============================================================

create index if not exists profiles_username_lower_idx
on public.profiles (
    lower(username)
);

create index if not exists profiles_full_name_lower_idx
on public.profiles (
    lower(full_name)
);

create index if not exists profiles_country_lower_idx
on public.profiles (
    lower(country)
);

create index if not exists profiles_city_lower_idx
on public.profiles (
    lower(city)
);


-- ============================================================
-- 4. END OF MIGRATION 028
-- ============================================================
