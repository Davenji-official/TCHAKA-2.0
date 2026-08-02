-- ============================================================
-- TCHAKA 2.0
-- Migration 014
-- Funding
-- ============================================================


-- ============================================================
-- FUNDING CAMPAIGNS
-- ============================================================

create table if not exists public.funding_campaigns (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null unique
        references public.projects(id)
        on delete cascade,

    creator_id uuid not null
        references public.profiles(id)
        on delete cascade,

    goal_amount numeric(14, 2) not null,

    currency text not null default 'USD',

    description text,

    status text not null default 'draft',

    starts_at timestamptz,

    ends_at timestamptz,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    constraint funding_goal_positive
        check (goal_amount > 0),

    constraint funding_currency_check
        check (
            currency in (
                'USD',
                'HTG',
                'EUR',
                'CAD'
            )
        ),

    constraint funding_status_check
        check (
            status in (
                'draft',
                'active',
                'paused',
                'completed',
                'cancelled'
            )
        ),

    constraint funding_dates_check
        check (
            ends_at is null
            or starts_at is null
            or ends_at > starts_at
        )
);


-- ============================================================
-- FUNDING CONTRIBUTIONS
-- ============================================================

create table if not exists public.funding_contributions (
    id uuid primary key default gen_random_uuid(),

    campaign_id uuid not null
        references public.funding_campaigns(id)
        on delete cascade,

    contributor_id uuid not null
        references public.profiles(id)
        on delete cascade,

    amount numeric(14, 2) not null,

    currency text not null default 'USD',

    status text not null default 'pending',

    payment_provider text,

    provider_reference text,

    created_at timestamptz not null default now(),

    completed_at timestamptz,

    constraint contribution_amount_positive
        check (amount > 0),

    constraint contribution_currency_check
        check (
            currency in (
                'USD',
                'HTG',
                'EUR',
                'CAD'
            )
        ),

    constraint contribution_status_check
        check (
            status in (
                'pending',
                'processing',
                'completed',
                'failed',
                'refunded',
                'cancelled'
            )
        )
);


-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists funding_campaigns_creator_idx
    on public.funding_campaigns (creator_id);

create index if not exists funding_campaigns_status_idx
    on public.funding_campaigns (status);

create index if not exists funding_contributions_campaign_idx
    on public.funding_contributions (campaign_id);

create index if not exists funding_contributions_contributor_idx
    on public.funding_contributions (contributor_id);

create index if not exists funding_contributions_status_idx
    on public.funding_contributions (status);


-- ============================================================
-- RLS
-- ============================================================

alter table public.funding_campaigns enable row level security;
alter table public.funding_contributions enable row level security;


-- ============================================================
-- CAMPAIGN READ
-- ============================================================

create policy "funding_campaigns_select_public"
on public.funding_campaigns
for select
using (
    status = 'active'
    or creator_id = auth.uid()
);


-- ============================================================
-- CAMPAIGN CREATE
-- ============================================================

create policy "funding_campaigns_insert_owner"
on public.funding_campaigns
for insert
to authenticated
with check (
    auth.uid() = creator_id
    and exists (
        select 1
        from public.projects p
        where p.id = funding_campaigns.project_id
        and p.creator_id = auth.uid()
    )
);


-- ============================================================
-- CAMPAIGN UPDATE
-- ============================================================

create policy "funding_campaigns_update_owner"
on public.funding_campaigns
for update
to authenticated
using (
    auth.uid() = creator_id
)
with check (
    auth.uid() = creator_id
);


-- ============================================================
-- CAMPAIGN DELETE
-- ============================================================

create policy "funding_campaigns_delete_owner"
on public.funding_campaigns
for delete
to authenticated
using (
    auth.uid() = creator_id
);


-- ============================================================
-- CONTRIBUTIONS
-- ============================================================

create policy "funding_contributions_select_own"
on public.funding_contributions
for select
to authenticated
using (
    auth.uid() = contributor_id
);


create policy "funding_contributions_insert_own"
on public.funding_contributions
for insert
to authenticated
with check (
    auth.uid() = contributor_id
);


create policy "funding_contributions_update_own"
on public.funding_contributions
for update
to authenticated
using (
    auth.uid() = contributor_id
)
with check (
    auth.uid() = contributor_id
);
