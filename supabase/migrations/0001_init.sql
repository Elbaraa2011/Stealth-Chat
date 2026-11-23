-- Stealth Chat backend schema.
--
-- Paste this whole file into the Supabase SQL editor (Dashboard -> SQL -> New
-- query -> Run) once per project. It is safe to re-run.
--
-- Tables
--   public.users        one row per account; `username` is the handle people
--                       type into the DM search to find each other.
--   public.dm_messages  the covert direct messages, one row per message.
--
-- Access
--   Both tables are protected by row level security. A signed-in user can read
--   every profile (needed for username lookup) but only their own messages.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------- profiles

create table if not exists public.users (
  id            uuid primary key references auth.users (id) on delete cascade,
  username      text not null,
  display_name  text not null default 'User',
  email         text,
  avatar        text not null default '',
  created_at    timestamptz not null default now()
);

create unique index if not exists users_username_lower_key
  on public.users (lower(username));

alter table public.users enable row level security;

drop policy if exists users_select_authenticated on public.users;
create policy users_select_authenticated
  on public.users for select
  to authenticated
  using (true);

drop policy if exists users_insert_self on public.users;
create policy users_insert_self
  on public.users for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists users_update_self on public.users;
create policy users_update_self
  on public.users for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ------------------------------------------------------------- direct messages

create table if not exists public.dm_messages (
  id             uuid primary key default gen_random_uuid(),
  from_id        uuid not null references public.users (id) on delete cascade,
  from_username  text not null,
  to_id          uuid not null references public.users (id) on delete cascade,
  to_username    text not null,
  body           text not null check (char_length(body) between 1 and 4000),
  read           boolean not null default false,
  created_at     timestamptz not null default now()
);

create index if not exists dm_messages_thread_idx
  on public.dm_messages (from_id, to_id, created_at desc);
create index if not exists dm_messages_inbox_idx
  on public.dm_messages (to_id, read);

alter table public.dm_messages enable row level security;

drop policy if exists dm_select_participants on public.dm_messages;
create policy dm_select_participants
  on public.dm_messages for select
  to authenticated
  using (from_id = auth.uid() or to_id = auth.uid());

drop policy if exists dm_insert_sender on public.dm_messages;
create policy dm_insert_sender
  on public.dm_messages for insert
  to authenticated
  with check (from_id = auth.uid());

drop policy if exists dm_update_recipient on public.dm_messages;
create policy dm_update_recipient
  on public.dm_messages for update
  to authenticated
  using (to_id = auth.uid())
  with check (to_id = auth.uid());

-- ------------------------------------------------- login by username helper
--
-- The login card accepts "username or email". The app resolves a username to
-- the account email through this function, so no email address ever has to be
-- readable through the normal (RLS) select path.

create or replace function public.login_email_for(handle text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email
  from public.users
  where lower(username) = lower(trim(handle))
  limit 1;
$$;

grant execute on function public.login_email_for(text) to anon, authenticated;

-- --------------------------------------------- profile row on every sign-up

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, username, display_name, email)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'username', ''),
             'user_' || substr(new.id::text, 1, 8)),
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''),
             split_part(coalesce(new.email, 'user'), '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
exception
  when unique_violation then
    -- Handle already taken: fall back to a guaranteed-unique handle.
    insert into public.users (id, username, display_name, email)
    values (
      new.id,
      'user_' || substr(new.id::text, 1, 8),
      coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''),
               split_part(coalesce(new.email, 'user'), '@', 1)),
      new.email
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
