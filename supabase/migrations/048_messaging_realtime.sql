-- ============================================================
-- TCHAKA 2.0
-- Migration 048
-- Messaging realtime publication
-- ============================================================

-- Realtime is required by the Flutter chat screen. The checks keep
-- this migration idempotent if a table was already added manually.

do $$
begin
    if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'messages'
    ) then
        alter publication supabase_realtime add table public.messages;
    end if;
end
$$;

comment on table public.messages is 'TCHAKA realtime chat messages';
