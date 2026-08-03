-- ============================================================
-- TCHAKA 2.0
-- Migration 031
-- Project ↔ Talent matching
-- ============================================================


-- ============================================================
-- 1. MATCH TALENTS TO PROJECT
-- ============================================================

create or replace function public.match_project_talents(
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

    candidate_matches as (
        select
            us.profile_id,

            count(distinct us.skill_id) as matching_skills,

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

        coalesce(cm.matching_skills, 0)::bigint
            as matching_skills,

        (
            select count(*)
            from project_required_skills prs
            where prs.required = true
        )::bigint
            as required_skills,

        coalesce(cm.matched_required_skills, 0)::bigint
            as matched_required_skills,

        coalesce(
            cm.average_proficiency,
            0
        )::numeric
            as average_proficiency,

        (
            lower(coalesce(p.country, ''))
            =
            lower(coalesce(
                (
                    select pd.country
                    from project_data pd
                ),
                ''
            ))
            and nullif(
                trim(coalesce(p.country, '')),
                ''
            ) is not null
        ) as location_match,

        (
            coalesce(cm.matching_skills, 0) * 10

            + coalesce(cm.matched_required_skills, 0) * 20

            + coalesce(cm.average_proficiency, 0) * 2

            + case
                when p.is_verified then 5
                else 0
              end

            + case
                when lower(coalesce(p.country, ''))
                     =
                     lower(coalesce(
                         (
                             select pd.country
                             from project_data pd
                         ),
                         ''
                     ))
                     and nullif(
                         trim(coalesce(p.country, '')),
                         ''
                     ) is not null
                then 5
                else 0
              end
        )::numeric
            as matching_score

    from candidate_matches cm

    join public.profiles p
        on p.id = cm.profile_id

    order by
        matching_score desc,
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
on function public.match_project_talents(
    uuid,
    integer,
    integer
)
from public, anon;

grant execute
on function public.match_project_talents(
    uuid,
    integer,
    integer
)
to authenticated;


-- ============================================================
-- 3. PERFORMANCE INDEXES
-- ============================================================

create index if not exists user_skills_skill_profile_proficiency_idx
on public.user_skills (
    skill_id,
    profile_id,
    proficiency desc
);

create index if not exists project_skills_project_required_skill_idx
on public.project_skills (
    project_id,
    required,
    skill_id
);


-- ============================================================
-- END OF MIGRATION 031
-- ============================================================
