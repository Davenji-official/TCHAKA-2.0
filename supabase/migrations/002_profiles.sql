-- ============================================================
-- TCHAKA 2.0
-- Migration 002
-- Profiles
-- ============================================================

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,

    username text unique,
    full_name text,
    avatar_url text,
    bio text,

    country text,
    city text,

    is_verified boolean not null default false,
    is_premium boolean not null default false,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint profiles_username_length
        check (
            username is null
            or char_length(username) between 3 and 30
        )
);

create index if not exists profiles_username_idx
    on public.profiles (username);

create index if not exists profiles_country_idx
    on public.profiles (country);

alter table public.profiles enable row level security;
