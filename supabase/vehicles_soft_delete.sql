alter table public.vehicles
  add column if not exists is_deleted boolean not null default false;

create index if not exists vehicles_is_deleted_idx
  on public.vehicles (is_deleted);
