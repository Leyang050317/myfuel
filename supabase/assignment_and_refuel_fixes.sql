-- Run this once in the Supabase SQL Editor after resolving any duplicate
-- assignments reported by the first query.

-- Existing duplicates must be resolved deliberately before the unique index
-- can be created. This query lists them without changing production data.
select
  assigned_user_id,
  count(*) as assigned_vehicle_count,
  array_agg(plate_number order by plate_number) as plate_numbers
from public.vehicles
where assigned_user_id is not null and is_deleted = false
group by assigned_user_id
having count(*) > 1;

create unique index if not exists vehicles_one_active_assignment_per_driver_idx
  on public.vehicles (assigned_user_id)
  where assigned_user_id is not null and is_deleted = false;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'refuel_records'
  ) then
    alter publication supabase_realtime add table public.refuel_records;
  end if;
end
$$;
