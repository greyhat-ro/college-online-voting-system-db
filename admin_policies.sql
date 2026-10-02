-- Enable RLS

alter table public.elections enable row level security;
alter table public.positions enable row level security;
alter table public.candidates enable row level security;


-- Helper function to check administrator role

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.profiles
        where id = auth.uid()
        and role = 'admin'
    );
$$;


-- Admin can create elections

create policy "Admins can insert elections"
on public.elections
for insert
to authenticated
with check (
    public.is_admin()
);


-- Admin can update elections

create policy "Admins can update elections"
on public.elections
for update
to authenticated
using (
    public.is_admin()
)
with check (
    public.is_admin()
);


-- Admin can insert positions

create policy "Admins can insert positions"
on public.positions
for insert
to authenticated
with check (
    public.is_admin()
);


-- Admin can update positions

create policy "Admins can update positions"
on public.positions
for update
to authenticated
using (
    public.is_admin()
)
with check (
    public.is_admin()
);


-- Admin can insert candidates

create policy "Admins can insert candidates"
on public.candidates
for insert
to authenticated
with check (
    public.is_admin()
);


-- Admin can update candidates

create policy "Admins can update candidates"
on public.candidates
for update
to authenticated
using (
    public.is_admin()
)
with check (
    public.is_admin()
);
