-- ============================================================
-- TCHAKA 2.0
-- Migration 049
-- Messaging integrity: read state + conversation ordering
-- ============================================================

-- Members must be able to update only their own read/mute state.
drop policy if exists "conversation_members_update_self"
on public.conversation_members;

create policy "conversation_members_update_self"
on public.conversation_members
for update
to authenticated
using (
    auth.uid() = profile_id
)
with check (
    auth.uid() = profile_id
);

-- Keep conversation ordering synchronized with the latest message.
create or replace function public.touch_conversation_on_message()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
    update public.conversations
    set updated_at = now()
    where id = new.conversation_id;

    return new;
end;
$$;

drop trigger if exists messages_touch_conversation
on public.messages;

create trigger messages_touch_conversation
after insert on public.messages
for each row
execute function public.touch_conversation_on_message();
