alter table public.vehicles enable row level security;

drop policy if exists "Allow public read vehicles"
on public.vehicles;

create policy "Allow public read vehicles"
on public.vehicles
for select
using (true);

drop policy if exists "Allow public update vehicles"
on public.vehicles;

create policy "Allow public update vehicles"
on public.vehicles
for update
using (true)
with check (true);
