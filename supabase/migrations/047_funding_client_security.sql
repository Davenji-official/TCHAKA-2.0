-- ============================================================
-- TCHAKA 2.0
-- Migration 047
-- Funding client-side security hardening
-- ============================================================

-- A mobile client may create only an unpaid/pending contribution.
-- Payment providers and server-side webhooks must be the only actors
-- allowed to mark a contribution completed, failed or refunded.

drop policy if exists "funding_contributions_insert_own"
on public.funding_contributions;

create policy "funding_contributions_insert_pending"
on public.funding_contributions
for insert
to authenticated
with check (
    auth.uid() = contributor_id
    and status = 'pending'
    and completed_at is null
    and payment_provider is null
    and provider_reference is null
);


drop policy if exists "funding_contributions_update_own"
on public.funding_contributions;

create policy "funding_contributions_cancel_own_pending"
on public.funding_contributions
for update
to authenticated
using (
    auth.uid() = contributor_id
    and status = 'pending'
)
with check (
    auth.uid() = contributor_id
    and status in ('pending', 'cancelled')
    and completed_at is null
    and payment_provider is null
    and provider_reference is null
);

comment on policy "funding_contributions_insert_pending"
on public.funding_contributions
is 'Clients can only create pending contributions; payment state is server-controlled.';
