create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  plate_number text not null unique,
  brand text not null,
  model text not null,
  fuel_type text not null,
  fuel_efficiency_km_per_liter numeric(6, 2) not null,
  tank_capacity_liters numeric(6, 2) not null,
  assigned_user_id uuid references public.users(id) on delete set null,
  status text not null default 'Available',
  notes text not null default '',
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists vehicles_assigned_user_id_idx
  on public.vehicles (assigned_user_id);

-- Business rule: one active vehicle per driver. A partial unique index also
-- protects against two admins assigning different vehicles at the same time.
create unique index if not exists vehicles_one_active_assignment_per_driver_idx
  on public.vehicles (assigned_user_id)
  where assigned_user_id is not null and is_deleted = false;

create index if not exists vehicles_is_deleted_idx
  on public.vehicles (is_deleted);
