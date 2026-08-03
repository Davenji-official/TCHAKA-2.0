-- ============================================================
-- TCHAKA 2.0
-- Migration 036
-- Enhanced project ↔ talent matching
-- ============================================================


-- ============================================================
-- 1. ENHANCED MATCHING FUNCTION
-- ============================================================

create or replace function public.match_project_talents_enhanced(
    p_project_id uuid,
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

    matching_skills bigint,
    required_skills bigint,
    matched_required_skills bigint,

    average_proficiency numeric,

    average_rating numeric,
    total_reviews bigint,
    completed_collaborations bigint,

    location_match boolean,

    matching_score numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
    with project_data as (
        select
            p.id,
            p.creator_id,
            p.country
        from public.projects p
        where p.id = p_project_id
          and (
              p.creator_id = (select auth.uid())
              or exists (
                  select 1
                  from public.project_members pm
                  where pm.project_id = p.id
                    and pm.profile_id = (select auth.uid())
                    and pm.status = 'active'
              )
          )
    ),

    project_required_skills as (
        select
            ps.skill_id,
            ps.required
        from public.project_skills ps
        where ps.project_id = p_project_id
    ),

    skill_matches as (
        select
            us.profile_id,

            count(distinct us.skill_id)
                as matching_skills,

            count(
                distinct case
                    when prs.required = true
                    then prs.skill_id
                end
            ) as required_skills,

            count(
                distinct case
                    when prs.required = true
                     and us.skill_id = prs.skill_id
                    then us.skill_id
                end
            ) as matched_required_skills,

            avg(
                coalesce(us.proficiency, 1)
            )::numeric as average_proficiency

        from public.user_skills us

        join project_required_skills prs
            on prs.skill_id = us.skill_id

        where us.profile_id <> (
            select pd.creator_id
            from project_data pd
        )

        group by us.profile_id
    ),

    reputation_data as (
        select
            cr.reviewee_id as profile_id,

            avg(cr.rating)::numeric
                as average_rating,

            count(cr.id)::bigint
                as total_reviews

        from public.collaboration_reviews cr

        group by cr.reviewee_id
    ),

    collaboration_data as (
        select
            pm.profile_id,

            count(distinct pm.project_id)::bigint
                as completed_collaborations

        from public.project_members pm

        join public.projects p
            on p.id = pm.project_id

        where pm.status = 'active'
          and p.status = 'completed'

        group by pm.profile_id
    )

    select
        p.id as profile_id,
        p.username,
        p.full_name,
        p.avatar_url,
        p.bio,
        p.country,
        p.city,
        p.is_verified,

        coalesce(
            sm.matching_skills,
            0
        )::bigint as matching_skills,

        (
            select count(*)
            from project_required_skills prs
            where prs.required = true
        )::bigint as required_skills,

        coalesce(
            sm.matched_required_skills,
            0
        )::bigint as matched_required_skills,

        coalesce(
            sm.average_proficiency,
            0
        )::numeric as average_proficiency,

        coalesce(
            rd.average_rating,
            0
        )::numeric as average_rating,

        coalesce(
            rd.total_reviews,
            0
        )::bigint as total_reviews,

        coalesce(
            cd.completed_collaborations,
            0
        )::bigint as completed_collaborations,

        (
            lower(coalesce(p.country, ''))
            =
            lower(
                coalesce(
                    (
                        select pd.country
                        from project_data pd
                    ),
                    ''
                )
            )
            and nullif(
                trim(coalesce(p.country, '')),
                ''
            ) is not null
        ) as location_match,

        (
            -- Skill matching
            coalesce(sm.matching_skills, 0) * 10

            -- Required skills
            + coalesce(
                sm.matched_required_skills,
                0
            ) * 25

            -- Skill proficiency
            + coalesce(
                sm.average_proficiency,
                0
            ) * 2

            -- Reputation
            + coalesce(
                rd.average_rating,
                0
            ) * 5

            -- Experience
            + least(
                coalesce(
                    cd.completed_collaborations,
                    0
                ),
                10
            ) * 2

            -- Verification
            + case
                when p.is_verified then 5
                else 0
              end

            -- Same country
            + case
                when lower(coalesce(p.country, ''))
                     =
                     lower(
                         coalesce(
                             (
                                 select pd.country
                                 from project_data pd
                             ),
                             ''
                         )
                     )
                     and nullif(
                         trim(coalesce(p.country, '')),
                         ''
                     ) is not null
                then 5
                else 0
              end

        )::numeric as matching_score

    from skill_matches sm

    join public.profiles p
        on p.id = sm.profile_id

    left join reputation_data rd
        on rd.profile_id = p.id

    left join collaboration_data cd
        on cd.profile_id = p.id

    order by
        matching_score desc,
        p.is_verified desc,
        coalesce(rd.average_rating, 0) desc,
        coalesce(cd.completed_collaborations, 0) desc,
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
on function public.match_project_talents_enhanced(
    uuid,
    integer,
    integer
)
from public, anon;

grant execute
on function public.match_project_talents_enhanced(
    uuid,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 3. PERFORMANCE INDEXES
-- ============================================================

create index if not exists collaboration_reviews_reviewee_rating_idx
on public.collaboration_reviews (
    reviewee_id,
    rating
);

create index if not exists project_members_profile_status_project_idx
on public.project_members (
    profile_id,
    status,
    project_id
);


-- ============================================================
-- 4. END
-- ============================================================
