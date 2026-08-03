-- ============================================================
-- TCHAKA 2.0
-- Migration 024
-- Project discovery feed
-- ============================================================

create or replace function public.get_project_feed(
    p_limit integer default 20,
    p_offset integer default 0
)
returns table (
    id uuid,
    creator_id uuid,
    title text,
    slug text,
    description text,
    category text,
    country text,
    city text,
    cover_image_url text,
    status text,
    visibility text,
    created_at timestamptz,
    published_at timestamptz,
    likes_count bigint,
    comments_count bigint,
    matching_skills_count bigint,
    feed_score numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
    with visible_projects as (
        select
            p.*
        from public.projects p
        where p.visibility = 'public'
          and p.status = 'published'
    ),

    project_stats as (
        select
            vp.id as project_id,

            (
                select count(*)
                from public.project_likes pl
                where pl.project_id = vp.id
            ) as likes_count,

            (
                select count(*)
                from public.comments c
                where c.project_id = vp.id
                  and c.deleted_at is null
            ) as comments_count

        from visible_projects vp
    ),

    skill_matches as (
        select
            ps.project_id,
            count(*) as matching_skills_count
        from public.project_skills ps
        join public.user_skills us
            on us.skill_id = ps.skill_id
        where us.profile_id = (select auth.uid())
        group by ps.project_id
    )

    select
        vp.id,
        vp.creator_id,
        vp.title,
        vp.slug,
        vp.description,
        vp.category,
        vp.country,
        vp.city,
        vp.cover_image_url,
        vp.status,
        vp.visibility,
        vp.created_at,
        vp.published_at,

        coalesce(ps.likes_count, 0) as likes_count,

        coalesce(ps.comments_count, 0) as comments_count,

        coalesce(sm.matching_skills_count, 0)
            as matching_skills_count,

        (
            coalesce(sm.matching_skills_count, 0) * 10
            +
            coalesce(ps.likes_count, 0) * 2
            +
            coalesce(ps.comments_count, 0)
            +
            greatest(
                0,
                30 - extract(
                    day from (
                        now() - coalesce(
                            vp.published_at,
                            vp.created_at
                        )
                    )
                )
            )
        )::numeric as feed_score

    from visible_projects vp

    left join project_stats ps
        on ps.project_id = vp.id

    left join skill_matches sm
        on sm.project_id = vp.id

    order by
        feed_score desc,
        vp.published_at desc nulls last,
        vp.created_at desc

    limit greatest(
        1,
        least(coalesce(p_limit, 20), 100)
    )

    offset greatest(
        0,
        coalesce(p_offset, 0)
    );
$$;


-- ============================================================
-- FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.get_project_feed(integer, integer)
from public, anon;

grant execute
on function public.get_project_feed(integer, integer)
to authenticated;


-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================

create index if not exists project_skills_project_skill_idx
on public.project_skills (
    project_id,
    skill_id
);

create index if not exists user_skills_profile_skill_idx
on public.user_skills (
    profile_id,
    skill_id
);

create index if not exists projects_published_created_idx
on public.projects (
    published_at desc,
    created_at desc
)
where visibility = 'public'
  and status = 'published';


-- ============================================================
-- END OF MIGRATION 024
-- ============================================================
