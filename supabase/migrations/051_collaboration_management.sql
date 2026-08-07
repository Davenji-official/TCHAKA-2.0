-- ============================================================
-- TCHAKA 2.0
-- Migration 051
-- Collaboration member access and owner management
-- ============================================================

create or replace function public.get_project_members(
    p_project_id uuid
)
returns table (
    profile_id uuid,
    role text,
    status text,
    joined_at timestamptz,
    username text,
    full_name text,
    avatar_url text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := (select auth.uid());
begin
    if v_uid is null then
        raise exception 'Authentication required';
    end if;

    if not exists (
        select 1
        from public.projects p
        where p.id = p_project_id
          and p.visibility <> 'private'
          and p.status <> 'archived'
    )
    and not exists (
        select 1
        from public.project_members pm
        where pm.project_id = p_project_id
          and pm.profile_id = v_uid
          and pm.status = 'active'
    ) then
        raise exception 'Project collaboration access denied';
    end if;

    return query
    select
        pm.profile_id,
        pm.role,
        pm.status,
        pm.joined_at,
        pp.username,
        pp.full_name,
        pp.avatar_url
    from public.project_members pm
    left join public.public_profiles pp
        on pp.id = pm.profile_id
    where pm.project_id = p_project_id
      and pm.status = 'active'
    order by pm.joined_at asc nulls last;
end;
$$;

create or replace function public.update_project_member_role(
    p_project_id uuid,
    p_profile_id uuid,
    p_role text
)
returns public.project_members
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_member public.project_members;
begin
    if (select auth.uid()) is null then
        raise exception 'Authentication required';
    end if;

    if not exists (
        select 1
        from public.projects p
        where p.id = p_project_id
          and p.creator_id = (select auth.uid())
    ) then
        raise exception 'Only the project owner can manage members';
    end if;

    if p_role not in (
        'admin',
        'developer',
        'designer',
        'marketing',
        'mentor',
        'contributor'
    ) then
        raise exception 'Invalid project member role';
    end if;

    if p_profile_id = (select auth.uid()) then
        raise exception 'Project owner role cannot be changed here';
    end if;

    update public.project_members
    set role = p_role
    where project_id = p_project_id
      and profile_id = p_profile_id
      and status = 'active'
      and role <> 'owner'
    returning * into v_member;

    if not found then
        raise exception 'Active project member not found';
    end if;

    return v_member;
end;
$$;

create or replace function public.remove_project_member(
    p_project_id uuid,
    p_profile_id uuid
)
returns public.project_members
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_member public.project_members;
begin
    if (select auth.uid()) is null then
        raise exception 'Authentication required';
    end if;

    if not exists (
        select 1
        from public.projects p
        where p.id = p_project_id
          and p.creator_id = (select auth.uid())
    ) then
        raise exception 'Only the project owner can remove members';
    end if;

    update public.project_members
    set status = 'removed'
    where project_id = p_project_id
      and profile_id = p_profile_id
      and status = 'active'
      and role <> 'owner'
    returning * into v_member;

    if not found then
        raise exception 'Active removable project member not found';
    end if;

    return v_member;
end;
$$;

revoke all on function public.get_project_members(uuid) from public;
revoke all on function public.update_project_member_role(uuid, uuid, text) from public;
revoke all on function public.remove_project_member(uuid, uuid) from public;

grant execute on function public.get_project_members(uuid) to authenticated;
grant execute on function public.update_project_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_project_member(uuid, uuid) to authenticated;
