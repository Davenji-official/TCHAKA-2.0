-- ============================================================
-- TCHAKA 2.0
-- Migration 030
-- Project recommendations
-- ============================================================


-- ============================================================
-- 1. RECOMMEND PROJECTS FOR A USER
-- ============================================================

create or replace function public.recommend_projects(
    p_profile_id uuid default auth.uid(),
    p_country text default null,
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
    matching_skills bigint,
    required_matching_skills bigint,
    like_score numeric,
    bookmark_score numeric,
    location_score numeric,
    recommendation_score numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
    with user_skills_cte as (
        select
            us.skill_id,
            coalesce(us.proficiency, 1) as proficiency
        from public.user_skills us
        where us.profile_id = p_profile_id
    ),

    visible_projects as (
        select
            p.id,
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
            p.funding_currency
        from public.projects p
        where
            p.visibility = 'public'
            and p.status = 'published'
            and p.creator_id <> p_profile_id
            and (
                nullif(trim(p_country), '') is null
                or lower(coalesce(p.country, ''))
                    = lower(trim(p_country))
                or lower(coalesce(p.country, ''))
                    = lower(coalesce(
                        (
                            select pr.country
                            from public.profiles pr
                            where pr.id = p_profile_id
                        ),
                        ''
                    ))
            )
    ),

    project_skill_scores as (
        select
            vp.id as project_id,

            count(ps.skill_id) as total_matching_skills,

            count(
                case
                    when ps.required = true
                    then ps.skill_id
                end
            ) as total_required_matching_skills,

            coalesce(
                sum(
                    case
                        when ps.required = true
                        then 2
                        else 1
                    end
                ),
                0
            ) as weighted_skill_score

        from visible_projects vp

        join public.project_skills ps
            on ps.project_id = vp.id

        join user_skills_cte us
            on us.skill_id = ps.skill_id

        group by vp.id
    ),

    project_likes_scores as (
        select
            vp.id as project_id,

            count(pl.profile_id) as like_count,

            count(
                case
                    when pl.profile_id = p_profile_id
                    then 1
                end
            ) as user_liked

        from visible_projects vp

        left join public.project_likes pl
            on pl.project_id = vp.id

        group by vp.id
    ),

    project_bookmark_scores as (
        select
            vp.id as project_id,

            count(pb.profile_id) as bookmark_count,

            count(
                case
                    when pb.profile_id = p_profile_id
                    then 1
                end
            ) as user_bookmarked

        from visible_projects vp

        left join public.project_bookmarks pb
            on pb.project_id = vp.id

        group by vp.id
    )

    select

        vp.id as project_id,
        vp.creator_id,
        vp.title,
        vp.slug,
        vp.description,
        vp.category,
        vp.country,
        vp.city,
        vp.cover_image_url,
        vp.status,
        vp.funding_goal,
        vp.funding_currency,

        coalesce(pss.total_matching_skills, 0)::bigint
            as matching_skills,

        coalesce(pss.total_required_matching_skills, 0)::bigint
            as required_matching_skills,

        coalesce(pls.like_count, 0)::numeric
            as like_score,

        coalesce(pbs.bookmark_count, 0)::numeric
            as bookmark_score,

        case
            when lower(coalesce(vp.country, ''))
                = lower(coalesce(
                    (
                        select pr.country
                        from public.profiles pr
                        where pr.id = p_profile_id
                    ),
                    ''
                ))
            then 1.0
            else 0.0
        end::numeric
            as location_score,

        (
            coalesce(pss.weighted_skill_score, 0) * 10

            + coalesce(pls.like_count, 0) * 0.05

            + coalesce(pbs.bookmark_count, 0) * 0.10

            + case
                when lower(coalesce(vp.country, ''))
                    = lower(coalesce(
                        (
                            select pr.country
                            from public.profiles pr
                            where pr.id = p_profile_id
                        ),
                        ''
                    ))
                then 5
                else 0
              end
        )::numeric
            as recommendation_score

    from visible_projects vp

    left join project_skill_scores pss
        on pss.project_id = vp.id

    left join project_likes_scores pls
        on pls.project_id = vp.id

    left join project_bookmark_scores pbs
        on pbs.project_id = vp.id

    order by
        recommendation_score desc,
        vp.created_at desc

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
on function public.recommend_projects(
    uuid,
    text,
    integer,
    integer
)
from public, anon;

grant execute
on function public.recommend_projects(
    uuid,
    text,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 3. RECOMMENDATION INDEXES
-- ============================================================

create index if not exists projects_visibility_status_creator_idx
on public.projects (
    visibility,
    status,
    creator_id
);

create index if not exists project_likes_project_profile_idx
on public.project_likes (
    project_id,
    profile_id
);

create index if not exists project_bookmarks_project_profile_idx
on public.project_bookmarks (
    project_id,
    profile_id
);


-- ============================================================
-- 4. END OF MIGRATION 030
-- ============================================================
