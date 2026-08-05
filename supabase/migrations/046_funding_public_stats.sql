-- ============================================================
-- TCHAKA 2.0
-- Migration 046
-- Public Funding Statistics
-- ============================================================

create or replace function public.get_project_funding_stats(
  p_project_id uuid
)
returns table (
  project_id uuid,
  goal_amount numeric,
  collected_amount numeric,
  remaining_amount numeric,
  progress_percent numeric,
  contributor_count bigint,
  currency text
)
language sql
security definer
set search_path = public
stable
as $$
select
    fc.project_id,

    fc.goal_amount,

    coalesce(
      sum(
        case
          when fcon.status = 'completed'
          then fcon.amount
          else 0
        end
      ),
      0
    ) as collected_amount,

    greatest(
      fc.goal_amount -
      coalesce(
        sum(
          case
            when fcon.status = 'completed'
            then fcon.amount
            else 0
          end
        ),
        0
      ),
      0
    ) as remaining_amount,
least(
      100,
      round(
        (
          coalesce(
            sum(
              case
                when fcon.status = 'completed'
                then fcon.amount
                else 0
              end
            ),
            0
          ) / nullif(fc.goal_amount, 0)
        ) * 100,
        2
      )
    ) as progress_percent,

    count(
      distinct case
        when fcon.status = 'completed'
        then fcon.contributor_id
      end
    ) as contributor_count,

    fc.currency

  from public.funding_campaigns fc

  left join public.funding_contributions fcon
    on fcon.campaign_id = fc.id

  where fc.project_id = p_project_id
    and fc.status = 'active'

  group by
    fc.project_id,
    fc.goal_amount,
    fc.currency;
$$;
-- ============================================================
-- SECURITY
-- ============================================================

revoke all
on function public.get_project_funding_stats(uuid)
from public;

grant execute
on function public.get_project_funding_stats(uuid)
to anon;

grant execute
on function public.get_project_funding_stats(uuid)
to authenticated;

comment on function public.get_project_funding_stats(uuid)
is
'Returns only aggregated public funding statistics for an active project campaign. Individual contribution records are never exposed.';
