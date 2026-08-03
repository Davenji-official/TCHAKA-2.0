-- ============================================================
-- TCHAKA 2.0
-- Migration 015
-- Security hardening
-- ============================================================

-- ============================================================
-- 1. AUTHENTICATION HELPER
-- ============================================================

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
    select auth.uid();
$$;


-- ============================================================
-- 2. SECURITY DEFINER HELPERS
--
-- These functions are intentionally kept in public for now
-- because they are referenced by RLS policies.
--
-- They use a fixed empty search_path and fully-qualified
-- table names to avoid search_path hijacking.
-- ============================================================

create or replace function public.is_conversation_member(
    p_conversation_id uuid,
    p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.conversation_members cm
        where cm.conversation_id = p_conversation_id
          and cm.profile_id = p_profile_id
    );
$$;


create or replace function public.is_project_member(
    p_project_id uuid,
    p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.project_members pm
        where pm.project_id = p_project_id
          and pm.profile_id = p_profile_id
          and pm.status = 'active'
    );
$$;


create or replace function public.is_project_owner(
    p_project_id uuid,
    p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.projects p
        where p.id = p_project_id
          and p.creator_id = p_profile_id
    );
$$;


-- ============================================================
-- 3. FUNCTION PRIVILEGES
-- ============================================================

revoke execute on function public.current_profile_id()
from anon;

grant execute on function public.current_profile_id()
to authenticated;

revoke execute on function public.is_conversation_member(uuid, uuid)
from public, anon;

grant execute on function public.is_conversation_member(uuid, uuid)
to authenticated;

revoke execute on function public.is_project_member(uuid, uuid)
from public, anon;

grant execute on function public.is_project_member(uuid, uuid)
to authenticated;

revoke execute on function public.is_project_owner(uuid, uuid)
from public, anon;

grant execute on function public.is_project_owner(uuid, uuid)
to authenticated;


-- ============================================================
-- 4. PROJECT SKILLS
-- ============================================================

drop policy if exists "project_skills_select"
on public.project_skills;

drop policy if exists "project_skills_insert_own"
on public.project_skills;

drop policy if exists "project_skills_delete_own"
on public.project_skills;


create policy "project_skills_select_visible"
on public.project_skills
for select
to authenticated
using (
    exists (
        select 1
        from public.projects p
        where p.id = project_skills.project_id
          and (
              (
                  p.visibility = 'public'
                  and p.status = 'published'
              )
              or p.creator_id = (select auth.uid())
              or public.is_project_member(
                  p.id,
                  (select auth.uid())
              )
          )
    )
);


create policy "project_skills_insert_owner"
on public.project_skills
for insert
to authenticated
with check (
    public.is_project_owner(
        project_skills.project_id,
        (select auth.uid())
    )
);


create policy "project_skills_update_owner"
on public.project_skills
for update
to authenticated
using (
    public.is_project_owner(
        project_skills.project_id,
        (select auth.uid())
    )
)
with check (
    public.is_project_owner(
        project_skills.project_id,
        (select auth.uid())
    )
);


create policy "project_skills_delete_owner"
on public.project_skills
for delete
to authenticated
using (
    public.is_project_owner(
        project_skills.project_id,
        (select auth.uid())
    )
);


-- ============================================================
-- 5. COMMENTS
-- ============================================================

drop policy if exists "comments_update_own"
on public.comments;

create policy "comments_update_own"
on public.comments
for update
to authenticated
using (
    comments.profile_id = (select auth.uid())
)
with check (
    comments.profile_id = (select auth.uid())
);


-- ============================================================
-- 6. PROJECT MEDIA
-- ============================================================

drop policy if exists "project_media_update_project_owner"
on public.project_media;

create policy "project_media_update_project_owner"
on public.project_media
for update
to authenticated
using (
    public.is_project_owner(
        project_media.project_id,
        (select auth.uid())
    )
    and project_media.uploaded_by = (select auth.uid())
)
with check (
    public.is_project_owner(
        project_media.project_id,
        (select auth.uid())
    )
    and project_media.uploaded_by = (select auth.uid())
);


-- ============================================================
-- 7. PROJECT MEMBERS
-- ============================================================

drop policy if exists "project_members_select_project_access"
on public.project_members;

drop policy if exists "project_members_insert_project_owner"
on public.project_members;

drop policy if exists "project_members_update_owner"
on public.project_members;

drop policy if exists "project_members_respond_own_invitation"
on public.project_members;

drop policy if exists "project_members_delete_owner"
on public.project_members;

drop policy if exists "project_members_leave_project"
on public.project_members;


create policy "project_members_select_project_access"
on public.project_members
for select
to authenticated
using (
    public.is_project_owner(
        project_members.project_id,
        (select auth.uid())
    )
    or (
        project_members.profile_id = (select auth.uid())
        and project_members.status in ('pending', 'active')
    )
    or public.is_project_member(
        project_members.project_id,
        (select auth.uid())
    )
);


create policy "project_members_insert_project_owner"
on public.project_members
for insert
to authenticated
with check (
    public.is_project_owner(
        project_members.project_id,
        (select auth.uid())
    )
    and project_members.invited_by = (select auth.uid())
);


create policy "project_members_update_owner"
on public.project_members
for update
to authenticated
using (
    public.is_project_owner(
        project_members.project_id,
        (select auth.uid())
    )
)
with check (
    public.is_project_owner(
        project_members.project_id,
        (select auth.uid())
    )
);


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


create policy "project_members_delete_owner"
on public.project_members
for delete
to authenticated
using (
    public.is_project_owner(
        project_members.project_id,
        (select auth.uid())
    )
);


create policy "project_members_leave_project"
on public.project_members
for delete
to authenticated
using (
    project_members.profile_id = (select auth.uid())
    and project_members.role <> 'owner'
);


-- ============================================================
-- 8. MESSAGING
-- ============================================================

drop policy if exists "conversations_select_member"
on public.conversations;

drop policy if exists "conversation_members_select_member"
on public.conversation_members;

drop policy if exists "messages_select_member"
on public.messages;

drop policy if exists "messages_insert_member"
on public.messages;

drop policy if exists "message_attachments_select_member"
on public.message_attachments;


create policy "conversations_select_member"
on public.conversations
for select
to authenticated
using (
    public.is_conversation_member(
        conversations.id,
        (select auth.uid())
    )
);


create policy "conversation_members_select_member"
on public.conversation_members
for select
to authenticated
using (
    public.is_conversation_member(
        conversation_members.conversation_id,
        (select auth.uid())
    )
);


create policy "messages_select_member"
on public.messages
for select
to authenticated
using (
    public.is_conversation_member(
        messages.conversation_id,
        (select auth.uid())
    )
);


create policy "messages_insert_member"
on public.messages
for insert
to authenticated
with check (
    messages.sender_id = (select auth.uid())
    and public.is_conversation_member(
        messages.conversation_id,
        (select auth.uid())
    )
);


create policy "message_attachments_select_member"
on public.message_attachments
for select
to authenticated
using (
    exists (
        select 1
        from public.messages m
        where m.id = message_attachments.message_id
          and public.is_conversation_member(
              m.conversation_id,
              (select auth.uid())
          )
    )
);


-- ============================================================
-- 9. FUNDING CONTRIBUTIONS
--
-- IMPORTANT:
-- Client applications must NOT be able to mark contributions
-- as completed by themselves.
--
-- Payment confirmation will be implemented later through
-- trusted server-side payment/webhook functions.
-- ============================================================

drop policy if exists "funding_contributions_insert_own"
on public.funding_contributions;

drop policy if exists "funding_contributions_update_own"
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
);


create policy "funding_contributions_update_own_pending"
on public.funding_contributions
for update
to authenticated
using (
    contributor_id = (select auth.uid())
    and status in ('pending', 'cancelled')
)
with check (
    contributor_id = (select auth.uid())
    and status in ('pending', 'cancelled')
);


-- ============================================================
-- 10. FUNDING CAMPAIGN OWNER VALIDATION
-- ============================================================

drop policy if exists "funding_campaigns_update_owner"
on public.funding_campaigns;

create policy "funding_campaigns_update_owner"
on public.funding_campaigns
for update
to authenticated
using (
    creator_id = (select auth.uid())
)
with check (
    creator_id = (select auth.uid())
    and exists (
        select 1
        from public.projects p
        where p.id = funding_campaigns.project_id
          and p.creator_id = (select auth.uid())
    )
);


-- ============================================================
-- 11. RLS INDEXES
-- ============================================================

create index if not exists project_members_project_profile_status_idx
on public.project_members (
    project_id,
    profile_id,
    status
);

create index if not exists conversation_members_conversation_profile_idx
on public.conversation_members (
    conversation_id,
    profile_id
);

create index if not exists funding_contributions_contributor_status_idx
on public.funding_contributions (
    contributor_id,
    status
);


-- ============================================================
-- END OF MIGRATION 015
-- ============================================================

