-- BookSphere Web schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'READER' check (role in ('READER','AUTHOR')),
  bio text,
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  author_name text not null,
  description text not null default '',
  genre text not null default 'Other',
  language text not null default 'English',
  price numeric(10,2) not null default 0 check (price >= 0),
  is_free boolean not null default false,
  total_pages integer not null default 1 check (total_pages >= 1),
  preview_pages integer not null default 3 check (preview_pages >= 1),
  cover_path text,
  manuscript_path text,
  preview_path text,
  status text not null default 'DRAFT' check (status in ('DRAFT','UPLOADING','PUBLISHED','FAILED','ARCHIVED')),
  copies_sold integer not null default 0,
  rating numeric(3,2) not null default 5.0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.library (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  progress numeric(5,4) not null default 0 check (progress >= 0 and progress <= 1),
  last_page integer not null default 1,
  completed boolean not null default false,
  purchased_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, book_id)
);

create table if not exists public.reading_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text not null default '',
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.reading_list_books (
  list_id uuid not null references public.reading_lists(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  primary key(list_id, book_id)
);

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.library enable row level security;
alter table public.reading_lists enable row level security;
alter table public.reading_list_books enable row level security;

drop policy if exists "published books are public" on public.books;
create policy "published books are public" on public.books for select using (status = 'PUBLISHED' or author_id = (select auth.uid()));

drop policy if exists "authors create own books" on public.books;
create policy "authors create own books" on public.books for insert to authenticated with check (author_id = (select auth.uid()) and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'AUTHOR'));

drop policy if exists "authors update own books" on public.books;
create policy "authors update own books" on public.books for update to authenticated using (author_id = (select auth.uid())) with check (author_id = (select auth.uid()));

drop policy if exists "authors delete own books" on public.books;
create policy "authors delete own books" on public.books for delete to authenticated using (author_id = (select auth.uid()));

drop policy if exists "profile self select" on public.profiles;
create policy "profile self select" on public.profiles for select to authenticated using (id = (select auth.uid()));
drop policy if exists "profile self insert" on public.profiles;
create policy "profile self insert" on public.profiles for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists "profile self update" on public.profiles;
create policy "profile self update" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "library self select" on public.library;
create policy "library self select" on public.library for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "library self insert" on public.library;
create policy "library self insert" on public.library for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "library self update" on public.library;
create policy "library self update" on public.library for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "lists self manage" on public.reading_lists;
create policy "lists self manage" on public.reading_lists for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists "list books self manage" on public.reading_list_books;
create policy "list books self manage" on public.reading_list_books for all to authenticated
using (exists (select 1 from public.reading_lists l where l.id = list_id and l.user_id = (select auth.uid())))
with check (exists (select 1 from public.reading_lists l where l.id = list_id and l.user_id = (select auth.uid())));

insert into storage.buckets (id,name,public) values
('covers','covers',true), ('previews','previews',true), ('manuscripts','manuscripts',false)
on conflict (id) do nothing;

drop policy if exists "public cover read" on storage.objects;
create policy "public cover read" on storage.objects for select using (bucket_id='covers');
drop policy if exists "author cover upload" on storage.objects;
create policy "author cover upload" on storage.objects for insert to authenticated
with check (bucket_id='covers' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "public preview read" on storage.objects;
create policy "public preview read" on storage.objects for select using (bucket_id='previews');
drop policy if exists "author preview upload" on storage.objects;
create policy "author preview upload" on storage.objects for insert to authenticated
with check (bucket_id='previews' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "author manuscript upload" on storage.objects;
create policy "author manuscript upload" on storage.objects for insert to authenticated
with check (bucket_id='manuscripts' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "manuscript owner read" on storage.objects;
create policy "manuscript owner read" on storage.objects for select to authenticated
using (bucket_id='manuscripts' and (storage.foldername(name))[1]=(select auth.uid())::text);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,email,name,role)
  values (new.id,new.email,coalesce(new.raw_user_meta_data->>'name','Reader'),
    case when coalesce(new.raw_user_meta_data->>'role','READER')='AUTHOR' then 'AUTHOR' else 'READER' end)
  on conflict (id) do update set email=excluded.email;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

grant select on public.books to anon, authenticated;
grant select,insert,update,delete on public.profiles, public.library, public.reading_lists, public.reading_list_books to authenticated;
grant select,insert,update,delete on public.books to authenticated;
