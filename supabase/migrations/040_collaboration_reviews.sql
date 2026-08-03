-- ============================================================
-- TCHAKA 2.0
-- Migration 040
-- Collaboration reviews & reputation
-- ============================================================


-- ============================================================
-- 1. COLLABORATION REVIEWS
-- ============================================================

create table if not exists public.collaboration_reviews (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    reviewer_id uuid not null
        references public.profiles(id)
        on delete cascade,

    reviewee_id uuid not null
        references public.profiles(id)
        on delete cascade,

    rating smallint not null,

    comment text,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    constraint collaboration_reviews_rating_check
        check (rating between 1 and 5),

    constraint collaboration_reviews_comment_length
        check (
            comment is null
            or char_length(comment) between 1 and 2000
        ),

    constraint collaboration_reviews_no_self_review
        check (reviewer_id <> reviewee_id),

    constraint collaboration_reviews_unique
        unique (
            project_id,
            reviewer_id,
            reviewee_id
        )
);


-- ============================================================
-- 2. INDEXES
-- ============================================================

create index if not exists collaboration_reviews_project_idx
on public.collaboration_reviews (
    project_id
);

create index if not exists collaboration_reviews_reviewer_idx
on public.collaboration_reviews (
    reviewer_id
);

create index if not exists collaboration_reviews_reviewee_idx
on public.collaboration_reviews (
    reviewee_id
);

create index if not exists collaboration_reviews_rating_idx
on public.collaboration_reviews (
    reviewee_id,
    rating
);

create index if not exists collaboration_reviews_created_at_idx
on public.collaboration_reviews (
    created_at desc
);


-- ============================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================

alter table public.collaboration_reviews
enable row level security;


-- ============================================================
-- 4. READ REVIEWS
-- ============================================================

create policy "collaboration_reviews_select_authenticated"
on public.collaboration_reviews
for select
to authenticated
using (
    true
);


-- ============================================================
-- 5. CREATE REVIEW
-- ============================================================

create policy "collaboration_reviews_insert_own"
on public.collaboration_reviews
for insert
to authenticated
with check (
    reviewer_id = (select auth.uid())

    and reviewer_id <> reviewee_id

    and exists (
        select 1
        from public.projects p
        where p.id = collaboration_reviews.project_id
          and p.status = 'completed'
    )

    and exists (
        select 1
        from public.project_members pm_reviewer
        where pm_reviewer.project_id =
            collaboration_reviews.project_id
          and pm_reviewer.profile_id =
            (select auth.uid())
          and pm_reviewer.status = 'active'
    )

    and exists (
        select 1
        from public.project_members pm_reviewee
        where pm_reviewee.project_id =
            collaboration_reviews.project_id
          and pm_reviewee.profile_id =
            collaboration_reviews.reviewee_id
          and pm_reviewee.status = 'active'
    )
);


-- ============================================================
-- 6. UPDATE OWN REVIEW
-- ============================================================

create policy "collaboration_reviews_update_own"
on public.collaboration_reviews
for update
to authenticated
using (
    reviewer_id = (select auth.uid())
)
with check (
    reviewer_id = (select auth.uid())
);


-- ============================================================
-- 7. DELETE OWN REVIEW
-- ============================================================

create policy "collaboration_reviews_delete_own"
on public.collaboration_reviews
for delete
to authenticated
using (
    reviewer_id = (select auth.uid())
);


-- ============================================================
-- 8. UPDATED_AT FUNCTION
-- ============================================================

create or replace function public.set_collaboration_review_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;


drop trigger if exists collaboration_reviews_updated_at
on public.collaboration_reviews;


create trigger collaboration_reviews_updated_at
before update on public.collaboration_reviews
for each row
execute function public.set_collaboration_review_updated_at();


-- ============================================================
-- 9. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.set_collaboration_review_updated_at()
from public, anon;

grant execute
on function public.set_collaboration_review_updated_at()
to authenticated;


-- ============================================================
-- 10. REPUTATION SUMMARY FUNCTION
-- ============================================================

create or replace function public.get_profile_reputation(
    p_profile_id uuid
)
returns table (
    average_rating numeric,
    total_reviews bigint,
    five_star_reviews bigint,
    four_star_reviews bigint,
    three_star_reviews bigint,
    two_star_reviews bigint,
    one_star_reviews bigint
)
language sql
stable
security invoker
set search_path = ''
as $$
    select
        coalesce(
            round(avg(cr.rating)::numeric, 2),
            0
        ) as average_rating,

        count(cr.id)::bigint
            as total_reviews,

        count(*) filter (
            where cr.rating = 5
        )::bigint as five_star_reviews,

        count(*) filter (
            where cr.rating = 4
        )::bigint as four_star_reviews,

        count(*) filter (
            where cr.rating = 3
        )::bigint as three_star_reviews,

        count(*) filter (
            where cr.rating = 2
        )::bigint as two_star_reviews,

        count(*) filter (
            where cr.rating = 1
        )::bigint as one_star_reviews

    from public.collaboration_reviews cr

    where cr.reviewee_id = p_profile_id;
$$;


-- ============================================================
-- 11. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.get_profile_reputation(uuid)
from public, anon;

grant execute
on function public.get_profile_reputation(uuid)
to authenticated;


-- ============================================================
-- END OF MIGRATION 040
-- ============================================================
