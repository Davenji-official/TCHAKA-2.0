-- ============================================================
-- TCHAKA 2.0
-- Migration 052
-- Public project feed RPC
-- ============================================================

create or replace function public.get_project_feed(
    p_limit integer default 20,
    p_offset integer default 0
)
returns setof jsonb
language sql
stable
security definer
set search_path = public
as $$
    select jsonb_build_object(
        'id', p.id,
        'creator_id', p.creator_id,
        'title', p.title,
        'slug', p.slug,
        'description', p.description,
        'category', p.category,
        'country', p.country,
        'city', p.city,
        'cover_image_url', p.cover_image_url,
        'status', p.status,
        'visibility', p.visibility,
        'funding_goal', p.funding_goal,
        'funding_currency', p.funding_currency,
        'team_size', p.team_size,
        'created_at', p.created_at,
        'updated_at', p.updated_at,
        'published_at', p.published_at,
        'creator_username', pr.username,
        'creator_full_name', pr.full_name,
        'creator_avatar_url', pr.avatar_url,
        'creator_is_verified', pr.is_verified,
        'likes_count', 0,
        'comments_count', 0,
        'followers_count', 0,
        'matching_skills_count', 0,
        'feed_score', 0,
        'impact_score', 0
    )
    from public.projects p
    left join public.profiles pr on pr.id = p.creator_id
    where p.status = 'published'
      and p.visibility = 'public'
    order by coalesce(p.published_at, p.created_at) desc, p.id desc
    limit greatest(1, least(coalesce(p_limit, 20), 100))
    offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.get_project_feed(integer, integer)
from public;

grant execute on function public.get_project_feed(integer, integer)
to authenticated;

grant execute on function public.get_project_feed(integer, integer)
to anon;
