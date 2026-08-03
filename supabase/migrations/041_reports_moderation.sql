-- ============================================================
-- TCHAKA 2.0
-- Migration 041
-- Reports & moderation
-- ============================================================


-- ============================================================
-- 1. REPORTS
-- ============================================================

create table if not exists public.reports (
    id uuid primary key default gen_random_uuid(),

    reporter_id uuid not null
        references public.profiles(id)
        on delete cascade,

    reported_profile_id uuid
        references public.profiles(id)
        on delete cascade,

    reported_project_id uuid
        references public.projects(id)
        on delete cascade,

    reported_comment_id uuid
        references public.comments(id)
        on delete cascade,

    reported_message_id uuid
        references public.messages(id)
        on delete cascade,

    reason text not null,

    description text,

    status text not null default 'pending',

    reviewed_by uuid
        references public.profiles(id)
        on delete set null,

    reviewed_at timestamptz,

    resolution_note text,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    constraint reports_reason_check
        check (
            reason in (
                'spam',
                'harassment',
                'fraud',
                'scam',
                'hate',
                'sexual_content',
                'violence',
                'copyright',
                'impersonation',
                'misinformation',
                'other'
            )
        ),

    constraint reports_status_check
        check (
            status in (
                'pending',
                'reviewing',
                'resolved',
                'dismissed'
            )
        ),

    constraint reports_description_length
        check (
            description is null
            or char_length(description) between 1 and 5000
        ),

    constraint reports_resolution_note_length
        check (
            resolution_note is null
            or char_length(resolution_note) between 1 and 5000
        ),

    constraint reports_single_target
        check (
            (
                case when reported_profile_id is not null then 1 else 0 end
                +
                case when reported_project_id is not null then 1 else 0 end
                +
                case when reported_comment_id is not null then 1 else 0 end
                +
                case when reported_message_id is not null then 1 else 0 end
            ) = 1
        )
);


-- ============================================================
-- 2. INDEXES
-- ============================================================

create index if not exists reports_reporter_idx
on public.reports (
    reporter_id
);

create index if not exists reports_profile_idx
on public.reports (
    reported_profile_id
);

create index if not exists reports_project_idx
on public.reports (
    reported_project_id
);

create index if not exists reports_comment_idx
on public.reports (
    reported_comment_id
);

create index if not exists reports_message_idx
on public.reports (
    reported_message_id
);

create index if not exists reports_status_idx
on public.reports (
    status
);

create index if not exists reports_created_at_idx
on public.reports (
    created_at desc
);


-- ============================================================
-- 3. RLS
-- ============================================================

alter table public.reports
enable row level security;


-- ============================================================
-- 4. REPORTER CAN READ OWN REPORTS
-- ============================================================

create policy "reports_select_own"
on public.reports
for select
to authenticated
using (
    reporter_id = (select auth.uid())
);


-- ============================================================
-- 5. CREATE REPORT
-- ============================================================

create policy "reports_insert_own"
on public.reports
for insert
to authenticated
with check (
    reporter_id = (select auth.uid())
);


-- ============================================================
-- 6. REPORTER CANNOT MODIFY REPORT
-- ============================================================

-- Deliberately no UPDATE policy for normal users.
-- Moderation actions will be performed through
-- trusted server-side functions in a future layer.


-- ============================================================
-- 7. UPDATED_AT
-- ============================================================

create or replace function public.set_report_updated_at()
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


drop trigger if exists reports_updated_at
on public.reports;


create trigger reports_updated_at
before update on public.reports
for each row
execute function public.set_report_updated_at();


-- ============================================================
-- 8. FUNCTION PRIVILEGES
-- ============================================================

revoke execute
on function public.set_report_updated_at()
from public, anon;

grant execute
on function public.set_report_updated_at()
to authenticated;


-- ============================================================
-- 9. END
-- ============================================================
