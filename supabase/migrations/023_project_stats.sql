-- ============================================================
-- TCHAKA 2.0
-- Migration 023
-- Project statistics and counters
-- ============================================================


-- ============================================================
-- 1. PROJECT STATISTICS FUNCTION
-- ============================================================

create or replace function public.get_project_stats(
    p_project_id uuid
)
returns table (
    project_id uuid,
    likes_count bigint,
    bookmarks_count bigint,
    comments_count bigint,
    members_count bigint,
    followers_count bigint,
    contributions_count bigint,
    completed_contributions_count bigint,
    amount_raised numeric,
    funding_goal numeric,
    funding_currency text,
    funding_progress numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        p.id as project_id,

        (
            select count(*)
            from public.project_likes pl
            where pl.project_id = p.id
        ) as likes_count,

        (
            select count(*)
            from public.project_bookmarks pb
            where pb.project_id = p.id
        ) as bookmarks_count,

        (
            select count(*)
            from public.comments c
            where c.project_id = p.id
              and c.deleted_at is null
        ) as comments_count,

        (
            select count(*)
            from public.project_members pm
            where pm.project_id = p.id
              and pm.status = 'active'
        ) as members_count,

        (
            select count(*)
            from public.follows f
            where f.following_id = p.creator_id
        ) as followers_count,

        (
            select count(*)
            from public.funding_contributions fc
            join public.funding_campaigns fca
                on fca.id = fc.campaign_id
            where fca.project_id = p.id
        ) as contributions_count,

        (
            select count(*)
            from public.funding_contributions fc
            join public.funding_campaigns fca
                on fca.id = fc.campaign_id
            where fca.project_id = p.id
              and fc.status = 'completed'
        ) as completed_contributions_count,

        coalesce(
            (
                select sum(fc.amount)
                from public.funding_contributions fc
                join public.funding_campaigns fca
                    on fca.id = fc.campaign_id
                where fca.project_id = p.id
                  and fc.status = 'completed'
                  and fc.currency = fca.currency
            ),
            0
        ) as amount_raised,

        (
            select fca.goal_amount
            from public.funding_campaigns fca
            where fca.project_id = p.id
            limit 1
        ) as funding_goal,

        (
            select fca.currency
            from public.funding_campaigns fca
            where fca.project_id = p.id
            limit 1
        ) as funding_currency,

        case
            when (
                select fca.goal_amount
                from public.funding_campaigns fca
                where fca.project_id = p.id
                limit 1
            ) is null
            then 0::numeric

            when (
                select fca.goal_amount
                from public.funding_campaigns fca
                where fca.project_id = p.id
                limit 1
            ) <= 0
            then 0::numeric

            else least(
                100::numeric,
                (
                    coalesce(
                        (
                            select sum(fc.amount)
                            from public.funding_contributions fc
                            join public.funding_campaigns fca
                                on fca.id = fc.campaign_id
                            where fca.project_id = p.id
                              and fc.status = 'completed'
                              and fc.currency = fca.currency
                        ),
                        0
                    )
                    /
                    (
                        select fca.goal_amount
                        from public.funding_campaigns fca
                        where fca.project_id = p.id
                        limit 1
                    )
                ) * 100
            )
        end as funding_progress

    from public.projects p
    where p.id = p_project_id

      and (
          (
              p.visibility = 'public'
              and p.status = 'published'
          )
          or p.creator_id = (select auth.uid())
          or exists (
              select 1
              from public.project_members pm
              where pm.project_id = p.id
                and pm.profile_id = (select auth.uid())
                and pm.status = 'active'
          )
      );
$$;


-- ============================================================
-- 2. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.get_project_stats(uuid)
from public, anon;

grant execute
on function public.get_project_stats(uuid)
to authenticated;


-- ============================================================
-- 3. PERFORMANCE INDEXES
-- ============================================================

create index if not exists project_likes_project_id_idx
on public.project_likes (project_id);

create index if not exists project_bookmarks_project_id_idx
on public.project_bookmarks (project_id);

create index if not exists comments_project_created_idx
on public.comments (
    project_id,
    created_at desc
);

create index if not exists project_members_project_status_idx
on public.project_members (
    project_id,
    status
);

create index if not exists funding_contributions_campaign_status_idx
on public.funding_contributions (
    campaign_id,
    status
);


-- ============================================================
-- END OF MIGRATION 023
-- ============================================================
