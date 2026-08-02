-- ============================================================
-- TCHAKA 2.0
-- Migration 008
-- Social interactions
-- ============================================================

-- ============================================================
-- FOLLOWS
-- ============================================================

create table if not exists public.follows (
    follower_id uuid not null
        references public.profiles(id)
        on delete cascade,

    following_id uuid not null
        references public.profiles(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (follower_id, following_id),

    constraint follows_no_self_follow
        check (follower_id <> following_id)
);

create index if not exists follows_follower_id_idx
    on public.follows (follower_id);

create index if not exists follows_following_id_idx
    on public.follows (following_id);


-- ============================================================
-- PROJECT LIKES
-- ============================================================

create table if not exists public.project_likes (
    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (project_id, profile_id)
);

create index if not exists project_likes_profile_id_idx
    on public.project_likes (profile_id);

create index if not exists project_likes_project_id_idx
    on public.project_likes (project_id);


-- ============================================================
-- PROJECT BOOKMARKS
-- ============================================================

create table if not exists public.project_bookmarks (
    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    profile_id uuid not null
        references public.profiles(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (project_id, profile_id)
);

create index if not exists project_bookmarks_profile_id_idx
    on public.project_bookmarks (profile_id);

create index if not exists project_bookmarks_project_id_idx
    on public.project_bookmarks (project_id);


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.follows enable row level security;
alter table public.project_likes enable row level security;
alter table public.project_bookmarks enable row level security;


-- ============================================================
-- FOLLOWS POLICIES
-- ============================================================

create policy "follows_select_authenticated"
on public.follows
for select
to authenticated
using (true);

create policy "follows_insert_own"
on public.follows
for insert
to authenticated
with check (
    auth.uid() = follower_id
    and follower_id <> following_id
);

create policy "follows_delete_own"
on public.follows
for delete
to authenticated
using (
    auth.uid() = follower_id
);


-- ============================================================
-- LIKES POLICIES
-- ============================================================

create policy "project_likes_select_authenticated"
on public.project_likes
for select
to authenticated
using (true);

create policy "project_likes_insert_own"
on public.project_likes
for insert
to authenticated
with check (
    auth.uid() = profile_id
);

create policy "project_likes_delete_own"
on public.project_likes
for delete
to authenticated
using (
    auth.uid() = profile_id
);


-- ============================================================
-- BOOKMARK POLICIES
-- ============================================================

create policy "project_bookmarks_select_own"
on public.project_bookmarks
for select
to authenticated
using (
    auth.uid() = profile_id
);

create policy "project_bookmarks_insert_own"
on public.project_bookmarks
for insert
to authenticated
with check (
    auth.uid() = profile_id
);

create policy "project_bookmarks_delete_own"
on public.project_bookmarks
for delete
to authenticated
using (
    auth.uid() = profile_id
);
