alter table public.users enable row level security;

drop policy if exists "Allow public read users for admin assignment"
on public.users;

create policy "Allow public read users for admin assignment"
on public.users
for select
using (true);
