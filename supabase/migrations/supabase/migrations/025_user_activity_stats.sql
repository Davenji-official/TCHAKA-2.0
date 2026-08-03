-- ============================================================
-- TCHAKA 2.0
-- Migration 025
-- User activity statistics
-- ============================================================


-- ============================================================
-- 1. USER ACTIVITY STATISTICS
-- ============================================================

create or replace function public.get_user_activity_stats(
    p_profile_id uuid
)
returns table (
    profile_id uuid,
    projects_created bigint,
    projects_published bigint,
    projects_completed bigint,
    projects_in_progress bigint,
    projects_joined bigint,
    active_projects_joined bigint,
    followers_count bigint,
    following_count bigint,
    likes_given bigint,
    bookmarks_count bigint,
    comments_count bigint,
    skills_count bigint,
    contributions_count bigint,
    completed_contributions_count bigint,
    total_amount_contributed numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id as profile_id,

        -- Projects created
        (
            select count(*)
            from public.projects pr
            where pr.creator_id = p.id
        ) as projects_created,

        -- Published projects
        (
            select count(*)
            from public.projects pr
            where pr.creator_id = p.id
              and pr.status = 'published'
        ) as projects_published,

        -- Completed projects
        (
            select count(*)
            from public.projects pr
            where pr.creator_id = p.id
              and pr.status = 'completed'
        ) as projects_completed,

        -- Projects currently active
        (
            select count(*)
            from public.projects pr
            where pr.creator_id = p.id
              and pr.status in ('published', 'paused')
        ) as projects_in_progress,

        -- Projects joined
        (
            select count(*)
            from public.project_members pm
            where pm.profile_id = p.id
              and pm.role <> 'owner'
        ) as projects_joined,

        -- Active projects joined
        (
            select count(*)
            from public.project_members pm
            where pm.profile_id = p.id
              and pm.role <> 'owner'
              and pm.status = 'active'
        ) as active_projects_joined,

        -- Followers
        (
            select count(*)
            from public.follows f
            where f.following_id = p.id
        ) as followers_count,

        -- Following
        (
            select count(*)
            from public.follows f
            where f.follower_id = p.id
        ) as following_count,

        -- Likes given
        (
            select count(*)
            from public.project_likes pl
            where pl.profile_id = p.id
        ) as likes_given,

        -- Bookmarks
        (
            select count(*)
            from public.project_bookmarks pb
            where pb.profile_id = p.id
        ) as bookmarks_count,

        -- Comments
        (
            select count(*)
            from public.comments c
            where c.profile_id = p.id
              and c.deleted_at is null
        ) as comments_count,

        -- Skills
        (
            select count(*)
            from public.user_skills us
            where us.profile_id = p.id
        ) as skills_count,

        -- Contributions
        (
            select count(*)
            from public.funding_contributions fc
            where fc.contributor_id = p.id
        ) as contributions_count,

        -- Completed contributions
        (
            select count(*)
            from public.funding_contributions fc
            where fc.contributor_id = p.id
              and fc.status = 'completed'
        ) as completed_contributions_count,

        -- Total contributed
        (
            select coalesce(sum(fc.amount), 0)
            from public.funding_contributions fc
            where fc.contributor_id = p.id
              and fc.status = 'completed'
        ) as total_amount_contributed

    from public.profiles p

    where p.id = p_profile_id

      and (
          p.id = (select auth.uid())

          or exists (
              select 1
              from public.projects pr
              where pr.creator_id = p.id
                and pr.visibility = 'public'
                and pr.status = 'published'
          )
      );
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.get_user_activity_stats(uuid)
from public, anon;

grant execute
on function public.get_user_activity_stats(uuid)
to authenticated;


-- ============================================================
-- 3. PERFORMANCE INDEXES
-- ============================================================

create index if not exists follows_following_follower_idx
on public.follows (
    following_id,
    follower_id
);

create index if not exists follows_follower_following_idx
on public.follows (
    follower_id,
    following_id
);

create index if not exists project_likes_profile_project_idx
on public.project_likes (
    profile_id,
    project_id
);

create index if not exists project_bookmarks_profile_project_idx
on public.project_bookmarks (
    profile_id,
    project_id
);

create index if not exists comments_profile_created_idx
on public.comments (
    profile_id,
    created_at desc
);

create index if not exists funding_contributions_contributor_created_idx
on public.funding_contributions (
    contributor_id,
    created_at desc
);


-- ============================================================
-- END OF MIGRATION 025
-- ============================================================
