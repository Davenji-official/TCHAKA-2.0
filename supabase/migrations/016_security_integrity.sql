-- ============================================================
-- TCHAKA 2.0
-- Migration 016
-- Security integrity fixes
-- ============================================================

-- ============================================================
-- 1. PROJECT MEMBER INVITATION SECURITY
--
-- A user who receives an invitation must only be able to
-- change the status of their own pending invitation.
--
-- They must NOT be able to change:
-- - project_id
-- - profile_id
-- - role
-- - invited_by
-- ============================================================

drop policy if exists "project_members_respond_own_invitation"
on public.project_members;


create policy "project_members_respond_own_invitation"
on public.project_members
for update
to authenticated
using (
    project_members.profile_id = (select auth.uid())
    and project_members.status = 'pending'
)
with check (
    project_members.profile_id = (select auth.uid())
    and project_members.status in ('active', 'declined')
);


-- ============================================================
-- 2. FUNDING CONTRIBUTIONS
--
-- A client application must not be allowed to modify an
-- existing contribution.
--
-- Payment status changes will later be performed by trusted
-- server-side payment/webhook logic.
-- ============================================================

drop policy if exists "funding_contributions_update_own_pending"
on public.funding_contributions;


-- No client UPDATE policy is intentionally created here.
--
-- Contributions can be:
-- INSERTED by the contributor as pending.
--
-- They cannot be changed directly from the client afterwards.
--
-- Later, trusted backend/webhook functions will handle:
-- pending
-- processing
-- completed
-- failed
-- refunded
-- cancelled


-- ============================================================
-- 3. FUNDING CONTRIBUTION INSERT HARDENING
-- ============================================================

drop policy if exists "funding_contributions_insert_pending"
on public.funding_contributions;


create policy "funding_contributions_insert_pending"
on public.funding_contributions
for insert
to authenticated
with check (
    contributor_id = (select auth.uid())
    and status = 'pending'
    and amount > 0

    and exists (
        select 1
        from public.funding_campaigns fc
        where fc.id = funding_contributions.campaign_id
          and fc.status = 'active'
    )

    and currency = (
        select fc.currency
        from public.funding_campaigns fc
        where fc.id = funding_contributions.campaign_id
    )
);


-- ============================================================
-- 4. PREVENT DIRECT CLIENT EXECUTION OF SECURITY HELPERS
--
-- The helpers are intended primarily for RLS evaluation.
-- Keep authenticated execution because the existing RLS
-- architecture references them.
-- ============================================================

revoke execute
on function public.is_conversation_member(uuid, uuid)
from public, anon;

revoke execute
on function public.is_project_member(uuid, uuid)
from public, anon;

revoke execute
on function public.is_project_owner(uuid, uuid)
from public, anon;


grant execute
on function public.is_conversation_member(uuid, uuid)
to authenticated;

grant execute
on function public.is_project_member(uuid, uuid)
to authenticated;

grant execute
on function public.is_project_owner(uuid, uuid)
to authenticated;


-- ============================================================
-- 5. UPDATED_AT HELPER
-- ============================================================

create or replace function public.set_updated_at()
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


revoke execute
on function public.set_updated_at()
from public, anon, authenticated;


-- ============================================================
-- 6. UPDATED_AT TRIGGERS
-- ============================================================

drop trigger if exists profiles_set_updated_at
on public.profiles;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();


drop trigger if exists projects_set_updated_at
on public.projects;

create trigger projects_set_updated_at
before update on public.projects
for each row
execute function public.set_updated_at();


drop trigger if exists comments_set_updated_at
on public.comments;

create trigger comments_set_updated_at
before update on public.comments
for each row
execute function public.set_updated_at();


drop trigger if exists conversations_set_updated_at
on public.conversations;

create trigger conversations_set_updated_at
before update on public.conversations
for each row
execute function public.set_updated_at();


drop trigger if exists funding_campaigns_set_updated_at
on public.funding_campaigns;

create trigger funding_campaigns_set_updated_at
before update on public.funding_campaigns
for each row
execute function public.set_updated_at();


-- ============================================================
-- 7. BASIC FUNDING DATA INTEGRITY
-- ============================================================

create index if not exists funding_campaigns_project_status_idx
on public.funding_campaigns (
    project_id,
    status
);


-- ============================================================
-- END OF MIGRATION 016
-- ============================================================
