-- Run this file once in the Supabase SQL Editor for an existing project.
-- It preserves any duplicate claims in an admin-only archive before enforcing
-- one fuel claim per completed trip.
begin;

create table if not exists public.fuel_claim_duplicates
  (like public.fuel_claims including all);
alter table public.fuel_claim_duplicates
  add column if not exists archived_at timestamptz not null default now();
alter table public.fuel_claim_duplicates enable row level security;
revoke all on public.fuel_claim_duplicates from anon, authenticated;

with ranked as (
  select id,
         row_number() over (
           partition by user_id, trip_id
           order by
             case status
               when 'Approved' then 0
               when 'Rejected' then 1
               else 2
             end,
             created_at,
             id
         ) as duplicate_number
  from public.fuel_claims
  where trip_id is not null
), duplicates as (
  select fuel_claims.*
  from public.fuel_claims
  join ranked using (id)
  where ranked.duplicate_number > 1
)
insert into public.fuel_claim_duplicates (
  id, user_id, vehicle_id, trip_id, vehicle_display_name, distance_km,
  fuel_type, fuel_efficiency_km_per_liter, fuel_price_per_liter,
  fuel_used_liters, claim_amount, co2_kg, emission_factor, status,
  rejection_reason, created_at, updated_at
)
select
  id, user_id, vehicle_id, trip_id, vehicle_display_name, distance_km,
  fuel_type, fuel_efficiency_km_per_liter, fuel_price_per_liter,
  fuel_used_liters, claim_amount, co2_kg, emission_factor, status,
  rejection_reason, created_at, updated_at
from duplicates
on conflict (id) do nothing;

with ranked as (
  select id,
         row_number() over (
           partition by user_id, trip_id
           order by
             case status
               when 'Approved' then 0
               when 'Rejected' then 1
               else 2
             end,
             created_at,
             id
         ) as duplicate_number
  from public.fuel_claims
  where trip_id is not null
)
delete from public.fuel_claims
using ranked
where public.fuel_claims.id = ranked.id
  and ranked.duplicate_number > 1;

create unique index if not exists fuel_claims_one_per_trip_idx
  on public.fuel_claims (user_id, trip_id)
  where trip_id is not null;

grant select, insert on public.fuel_claims to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'fuel_claims'
  ) then
    alter publication supabase_realtime add table public.fuel_claims;
  end if;
end $$;

notify pgrst, 'reload schema';
commit;

-- Verification: both values should be zero after the migration.
select count(*) as duplicate_trip_groups
from (
  select user_id, trip_id
  from public.fuel_claims
  where trip_id is not null
  group by user_id, trip_id
  having count(*) > 1
) duplicate_groups;

select count(*) as invalid_claim_statuses
from public.fuel_claims
where status not in ('Pending', 'Approved', 'Rejected');
