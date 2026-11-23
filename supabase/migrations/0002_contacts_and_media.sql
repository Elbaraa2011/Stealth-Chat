-- Stealth Chat: friends (dm_contacts), media messages and the media bucket.
--
-- Paste this whole file into the Supabase SQL editor (Dashboard -> SQL -> New
-- query -> Run) once per project, after 0001_init.sql. It is safe to re-run.
--
-- Adds
--   public.dm_contacts  one row per "friend" relationship. The Messages tab
--                       lists exactly these people, so the screen shows what
--                       the signed-in user added and nothing else.
--   media columns       image / voice attachments on dm_messages.
--   storage bucket      `dm-media`, public read, uploads restricted to the
--                       sender's own `<auth.uid()>/` folder.

-- ------------------------------------------------------------------ friends

create table if not exists public.dm_contacts (
  owner_id   uuid not null references public.users (id) on delete cascade,
  contact_id uuid not null references public.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (owner_id, contact_id),
  constraint dm_contacts_not_self check (owner_id <> contact_id)
);

create index if not exists dm_contacts_owner_idx
  on public.dm_contacts (owner_id, created_at desc);

alter table public.dm_contacts enable row level security;

drop policy if exists dm_contacts_select_own on public.dm_contacts;
create policy dm_contacts_select_own
  on public.dm_contacts for select
  to authenticated
  using (owner_id = auth.uid());

drop policy if exists dm_contacts_insert_own on public.dm_contacts;
create policy dm_contacts_insert_own
  on public.dm_contacts for insert
  to authenticated
  with check (owner_id = auth.uid());

drop policy if exists dm_contacts_delete_own on public.dm_contacts;
create policy dm_contacts_delete_own
  on public.dm_contacts for delete
  to authenticated
  using (owner_id = auth.uid());

-- ------------------------------------------------------------ media columns

alter table public.dm_messages
  add column if not exists media_url   text,
  add column if not exists media_type  text,
  add column if not exists duration_ms integer;

alter table public.dm_messages
  drop constraint if exists dm_messages_body_check;

alter table public.dm_messages
  add constraint dm_messages_body_check
  check (
    char_length(body) <= 4000
    and (char_length(body) > 0 or media_url is not null)
  );

alter table public.dm_messages
  drop constraint if exists dm_messages_media_type_check;

alter table public.dm_messages
  add constraint dm_messages_media_type_check
  check (media_type is null or media_type in ('image', 'voice'));

-- ------------------------------------------------------------ storage bucket

insert into storage.buckets (id, name, public)
values ('dm-media', 'dm-media', true)
on conflict (id) do update set public = true;

drop policy if exists dm_media_read on storage.objects;
create policy dm_media_read
  on storage.objects for select
  to authenticated, anon
  using (bucket_id = 'dm-media');

drop policy if exists dm_media_insert_own_folder on storage.objects;
create policy dm_media_insert_own_folder
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'dm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists dm_media_delete_own_folder on storage.objects;
create policy dm_media_delete_own_folder
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'dm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
