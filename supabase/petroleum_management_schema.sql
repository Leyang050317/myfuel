create table if not exists public.fuel_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  trip_id uuid null,
  vehicle_display_name text not null default '',
  distance_km numeric(10,2) not null check (distance_km >= 0),
  fuel_type text not null,
  fuel_efficiency_km_per_liter numeric(10,2) not null check (fuel_efficiency_km_per_liter > 0),
  fuel_price_per_liter numeric(10,2) not null check (fuel_price_per_liter >= 0),
  fuel_used_liters numeric(10,2) not null check (fuel_used_liters >= 0),
  claim_amount numeric(12,2) not null check (claim_amount >= 0),
  co2_kg numeric(12,3) not null check (co2_kg >= 0),
  emission_factor numeric(8,3) not null check (emission_factor >= 0),
  status text not null default 'Pending' check (status in ('Pending', 'Approved', 'Rejected')),
  rejection_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists fuel_claims_user_created_idx on public.fuel_claims (user_id, created_at desc);
create index if not exists fuel_claims_status_created_idx on public.fuel_claims (status, created_at desc);
create unique index if not exists fuel_claims_one_per_trip_idx
  on public.fuel_claims (user_id, trip_id)
  where trip_id is not null;

create table if not exists public.refuel_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  fuel_type text not null,
  refuelled_at timestamptz not null,
  odometer_km numeric(12,2) not null check (odometer_km >= 0),
  fuel_liters numeric(10,2) not null check (fuel_liters > 0),
  price_per_liter numeric(10,2) not null check (price_per_liter >= 0),
  total_cost numeric(12,2) not null check (total_cost >= 0),
  station_name text not null default '',
  is_full_tank boolean not null default false,
  notes text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists refuel_records_vehicle_date_idx on public.refuel_records (vehicle_id, refuelled_at desc);

alter table public.fuel_claims enable row level security;
alter table public.refuel_records enable row level security;
create policy "Users create own fuel claims" on public.fuel_claims for insert to authenticated with check (auth.uid() = user_id);
create policy "Users read own fuel claims" on public.fuel_claims for select to authenticated using (auth.uid() = user_id);
create policy "Current local admin reads fuel claims" on public.fuel_claims for select using (true);
create policy "Current local admin updates pending fuel claims" on public.fuel_claims for update using (status = 'Pending') with check (status in ('Approved', 'Rejected'));
create policy "Users create own refuel records" on public.refuel_records for insert to authenticated with check (auth.uid() = user_id);
create policy "Users read own refuel records" on public.refuel_records for select to authenticated using (auth.uid() = user_id);
create policy "Current local admin reads refuel records" on public.refuel_records for select using (true);

create or replace function public.enforce_fuel_claim_transition()
returns trigger language plpgsql as $$
begin
  if old.status <> 'Pending' then
    raise exception 'Approved and rejected fuel claims are read-only';
  end if;
  if new.status not in ('Approved', 'Rejected') then
    raise exception 'Fuel claim may only move from Pending to Approved or Rejected';
  end if;
  return new;
end;
$$;
drop trigger if exists fuel_claim_transition_guard on public.fuel_claims;
create trigger fuel_claim_transition_guard before update on public.fuel_claims
for each row execute function public.enforce_fuel_claim_transition();
