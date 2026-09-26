-- Run once in the Supabase SQL Editor. Existing objects are not dropped.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('article-photos','article-photos',false,20971520,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create table if not exists public.photo_assets (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 article_id text,
 object_path text unique not null,
 original_filename text not null,
 mime_type text not null,
 byte_size bigint not null,
 caption text not null default '',
 source text not null default '',
 source_style text not null default 'copyright' check(source_style in ('copyright','bracket')),
 shot_date date,
 verified_context text not null default '',
 generated boolean not null default false,
 created_at timestamptz not null default now(),
 constraint photo_owner_path check (split_part(object_path,'/',1)=owner_id::text)
);
alter table public.photo_assets enable row level security;
create policy "photo_assets_owner_select" on public.photo_assets for select to authenticated using (owner_id=(select auth.uid()));
create policy "photo_assets_owner_insert" on public.photo_assets for insert to authenticated with check (owner_id=(select auth.uid()));
create policy "photo_assets_owner_update" on public.photo_assets for update to authenticated using (owner_id=(select auth.uid())) with check (owner_id=(select auth.uid()));
create policy "photo_assets_owner_delete" on public.photo_assets for delete to authenticated using (owner_id=(select auth.uid()));

create policy "article_photos_owner_read" on storage.objects for select to authenticated
using (bucket_id='article-photos' and (storage.foldername(name))[1]=(select auth.uid()::text));
create policy "article_photos_owner_upload" on storage.objects for insert to authenticated
with check (bucket_id='article-photos' and (storage.foldername(name))[1]=(select auth.uid()::text));
create policy "article_photos_owner_delete" on storage.objects for delete to authenticated
using (bucket_id='article-photos' and (storage.foldername(name))[1]=(select auth.uid()::text));
