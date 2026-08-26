-- Run this file once in the Supabase SQL editor.
create table if not exists public.driver_live_locations (
  user_id uuid primary key references public.users(id) on delete cascade,
  trip_id uuid not null,
  driver_name text not null default '',
  vehicle_id uuid references public.vehicles(id) on delete set null,
  vehicle_name text not null default '',
  plate_number text not null default '',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_m double precision,
  speed_mps double precision,
  heading double precision,
  distance_km double precision not null default 0,
  destination_name text,
  destination_latitude double precision,
  destination_longitude double precision,
  started_at timestamptz not null,
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create index if not exists driver_live_locations_active_updated_idx
  on public.driver_live_locations (is_active, updated_at desc);

alter table public.driver_live_locations enable row level security;

drop policy if exists "Drivers insert own live location"
  on public.driver_live_locations;
create policy "Drivers insert own live location"
  on public.driver_live_locations for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Drivers update own live location"
  on public.driver_live_locations;
create policy "Drivers update own live location"
  on public.driver_live_locations for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- The current app uses a local admin account, so live rows must be readable by
-- the anon client. Replace this with an authenticated admin-role policy later.
drop policy if exists "Local admin reads live locations"
  on public.driver_live_locations;
create policy "Local admin reads live locations"
  on public.driver_live_locations for select
  using (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'driver_live_locations'
  ) then
    alter publication supabase_realtime
      add table public.driver_live_locations;
  end if;
end $$;
