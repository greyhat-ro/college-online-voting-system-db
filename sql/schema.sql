-- PostgreSQL/Supabase schema for the production version.
create table public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null,
 student_id text unique,
 role text not null default 'voter' check(role in('voter','admin')),
 created_at timestamptz not null default now()
);
create table public.elections(
 id bigint generated always as identity primary key,
 title text not null,
 description text,
 status text not null default 'draft' check(status in('draft','scheduled','active','closed','published')),
 starts_at timestamptz,
 ends_at timestamptz,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.positions(
 id bigint generated always as identity primary key,
 election_id bigint not null references public.elections(id) on delete cascade,
 name text not null,
 max_selections integer not null default 1 check(max_selections>0)
);
create table public.candidates(
 id bigint generated always as identity primary key,
 position_id bigint not null references public.positions(id) on delete cascade,
 name text not null,
 department text,
 manifesto text,
 photo_url text,
 active boolean not null default true
);
create table public.ballots(
 id bigint generated always as identity primary key,
 election_id bigint not null references public.elections(id) on delete cascade,
 voter_id uuid not null references auth.users(id) on delete cascade,
 candidate_id bigint not null references public.candidates(id) on delete restrict,
 position_id bigint not null references public.positions(id) on delete restrict,
 submitted_at timestamptz not null default now(),
 unique(election_id,voter_id,position_id)
);
create table public.audit_logs(
 id bigint generated always as identity primary key,
 actor_id uuid references auth.users(id),
 action text not null,
 entity_type text,
 entity_id text,
 created_at timestamptz not null default now(),
 metadata jsonb
);
alter table public.profiles enable row level security;
alter table public.elections enable row level security;
alter table public.positions enable row level security;
alter table public.candidates enable row level security;
alter table public.ballots enable row level security;
alter table public.audit_logs enable row level security;
-- Add narrowly scoped RLS policies for the chosen authentication/ballot-secrecy model.
-- Do not use blanket public INSERT/UPDATE policies for a real election.
