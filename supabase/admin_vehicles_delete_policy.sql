alter table public.vehicles enable row level security;

drop policy if exists "Allow public delete vehicles"
on public.vehicles;

create policy "Allow public delete vehicles"
on public.vehicles
for delete
using (true);
