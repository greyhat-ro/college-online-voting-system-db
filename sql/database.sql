-- =========================================================
-- CAMPUSVOTE
-- Complete Supabase Database
-- =========================================================


-- =========================================================
-- 1. PROFILES
-- =========================================================

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,

    full_name text not null,

    student_id text unique,

    role text not null default 'voter'
        check (role in ('voter', 'admin')),

    created_at timestamptz not null default now()
);


-- =========================================================
-- 2. ELECTIONS
-- =========================================================

create table public.elections (
    id bigint generated always as identity primary key,

    title text not null,

    description text,

    status text not null default 'draft'
        check (
            status in (
                'draft',
                'scheduled',
                'active',
                'closed',
                'published'
            )
        ),

    starts_at timestamptz,

    ends_at timestamptz,

    created_by uuid references auth.users(id),

    created_at timestamptz not null default now()
);


-- =========================================================
-- 3. POSITIONS
-- =========================================================

create table public.positions (
    id bigint generated always as identity primary key,

    election_id bigint not null
        references public.elections(id)
        on delete cascade,

    name text not null,

    max_selections integer not null default 1
        check (max_selections > 0)
);


-- =========================================================
-- 4. CANDIDATES
-- =========================================================

create table public.candidates (
    id bigint generated always as identity primary key,

    position_id bigint not null
        references public.positions(id)
        on delete cascade,

    name text not null,

    department text,

    manifesto text,

    photo_url text,

    active boolean not null default true
);


-- =========================================================
-- 5. BALLOTS
-- =========================================================

create table public.ballots (
    id bigint generated always as identity primary key,

    election_id bigint not null
        references public.elections(id)
        on delete cascade,

    voter_id uuid not null
        references auth.users(id)
        on delete cascade,

    candidate_id bigint not null
        references public.candidates(id)
        on delete restrict,

    position_id bigint not null
        references public.positions(id)
        on delete restrict,

    submitted_at timestamptz not null default now(),

    unique (
        election_id,
        voter_id,
        position_id
    )
);


-- =========================================================
-- 6. AUDIT LOGS
-- =========================================================

create table public.audit_logs (
    id bigint generated always as identity primary key,

    actor_id uuid references auth.users(id),

    action text not null,

    entity_type text,

    entity_id text,

    created_at timestamptz not null default now(),

    metadata jsonb
);


-- =========================================================
-- 7. ENABLE RLS
-- =========================================================

alter table public.profiles enable row level security;

alter table public.elections enable row level security;

alter table public.positions enable row level security;

alter table public.candidates enable row level security;

alter table public.ballots enable row level security;

alter table public.audit_logs enable row level security;


-- =========================================================
-- 8. PROFILE CREATION TRIGGER
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin

    insert into public.profiles (
        id,
        full_name,
        student_id,
        role
    )

    values (
        new.id,

        coalesce(
            new.raw_user_meta_data ->> 'full_name',
            'Student'
        ),

        new.raw_user_meta_data ->> 'student_id',

        'voter'
    );

    return new;

end;
$$;


drop trigger if exists on_auth_user_created
on auth.users;


create trigger on_auth_user_created

after insert on auth.users

for each row

execute function public.handle_new_user();


-- =========================================================
-- 9. ADMIN CHECK FUNCTION
-- =========================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$

    select exists (

        select 1

        from public.profiles

        where public.profiles.id = auth.uid()

        and public.profiles.role = 'admin'

    );

$$;


-- =========================================================
-- 10. PROFILE POLICY
-- =========================================================

create policy "Users can view own profile"

on public.profiles

for select

to authenticated

using (
    id = auth.uid()
);


-- =========================================================
-- 11. ELECTION READ POLICY
-- =========================================================

create policy "Authenticated users can view elections"

on public.elections

for select

to authenticated

using (
    status in ('active', 'closed', 'published')
);


-- =========================================================
-- 12. POSITION READ POLICY
-- =========================================================

create policy "Authenticated users can view positions"

on public.positions

for select

to authenticated

using (

    exists (

        select 1

        from public.elections e

        where e.id = positions.election_id

        and e.status in (
            'active',
            'closed',
            'published'
        )

    )

);


-- =========================================================
-- 13. CANDIDATE READ POLICY
-- =========================================================

create policy "Authenticated users can view candidates"

on public.candidates

for select

to authenticated

using (

    active = true

    and exists (

        select 1

        from public.positions p

        join public.elections e

            on e.id = p.election_id

        where p.id = candidates.position_id

        and e.status in (
            'active',
            'closed',
            'published'
        )

    )

);


-- =========================================================
-- 14. ADMIN ELECTION MANAGEMENT
-- =========================================================

create policy "Admins can insert elections"

on public.elections

for insert

to authenticated

with check (
    public.is_admin()
);


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


-- =========================================================
-- 15. ADMIN POSITION MANAGEMENT
-- =========================================================

create policy "Admins can insert positions"

on public.positions

for insert

to authenticated

with check (
    public.is_admin()
);


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


-- =========================================================
-- 16. ADMIN CANDIDATE MANAGEMENT
-- =========================================================

create policy "Admins can insert candidates"

on public.candidates

for insert

to authenticated

with check (
    public.is_admin()
);


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


-- =========================================================
-- 17. CAST VOTE FUNCTION
-- =========================================================

create or replace function public.cast_vote(
    p_election_id bigint,
    p_votes jsonb
)

returns jsonb

language plpgsql

security definer

set search_path = ''

as $$

declare

    v_user_id uuid;

    v_vote jsonb;

    v_position_id bigint;

    v_candidate_id bigint;

    v_election_status text;

begin

    -- Get logged-in user

    v_user_id := auth.uid();


    if v_user_id is null then

        raise exception 'You must be logged in to vote';

    end if;


    -- Check election

    select status

    into v_election_status

    from public.elections

    where id = p_election_id;


    if v_election_status is null then

        raise exception 'Election not found';

    end if;


    if v_election_status <> 'active' then

        raise exception 'Election is not currently active';

    end if;


    -- Validate each selected vote

    for v_vote in
        select value
        from jsonb_array_elements(p_votes)

    loop

        v_position_id :=
            (v_vote ->> 'position_id')::bigint;

        v_candidate_id :=
            (v_vote ->> 'candidate_id')::bigint;


        -- Candidate must belong to the selected position
        -- and that position must belong to this election.

        if not exists (

            select 1

            from public.candidates c

            join public.positions p

                on p.id = c.position_id

            where c.id = v_candidate_id

            and c.position_id = v_position_id

            and p.election_id = p_election_id

            and c.active = true

        ) then

            raise exception
                'Invalid candidate selection';

        end if;


        -- Insert ballot.

        insert into public.ballots (

            election_id,

            voter_id,

            candidate_id,

            position_id

        )

        values (

            p_election_id,

            v_user_id,

            v_candidate_id,

            v_position_id

        );

    end loop;


    -- Audit successful vote submission.

    insert into public.audit_logs (

        actor_id,

        action,

        entity_type,

        entity_id,

        metadata

    )

    values (

        v_user_id,

        'VOTE_SUBMITTED',

        'election',

        p_election_id::text,

        jsonb_build_object(

            'positions_voted',
            jsonb_array_length(p_votes)

        )

    );


    return jsonb_build_object(

        'success',
        true,

        'message',
        'Vote submitted successfully'

    );

exception

    when unique_violation then

        raise exception
            'You have already voted in this election';

end;

$$;


-- Only logged-in users can call it.

revoke execute
on function public.cast_vote(bigint, jsonb)
from public;


grant execute
on function public.cast_vote(bigint, jsonb)
to authenticated;


-- =========================================================
-- 18. RESULTS FUNCTION
-- =========================================================

create or replace function public.get_live_results(
    p_election_id bigint
)

returns table (

    position_id bigint,

    position_name text,

    candidate_id bigint,

    candidate_name text,

    vote_count bigint

)

language sql

security definer

set search_path = ''

as $$

    select

        p.id,

        p.name,

        c.id,

        c.name,

        count(b.id)::bigint

    from public.positions p

    join public.candidates c

        on c.position_id = p.id

    left join public.ballots b

        on b.candidate_id = c.id

        and b.position_id = p.id

        and b.election_id = p.election_id

    where p.election_id = p_election_id

    group by

        p.id,

        p.name,

        c.id,

        c.name

    order by

        p.id,

        count(b.id) desc,

        c.name;

$$;


revoke execute
on function public.get_live_results(bigint)
from public;


grant execute
on function public.get_live_results(bigint)
to authenticated;


-- =========================================================
-- 19. ADMIN AUDIT LOG ACCESS
-- =========================================================

create policy "Admins can view audit logs"

on public.audit_logs

for select

to authenticated

using (
    public.is_admin()
);


-- =========================================================
-- 20. ADMIN AUDIT LOG INSERT
-- =========================================================

create policy "Admins can insert audit logs"

on public.audit_logs

for insert

to authenticated

with check (
    public.is_admin()
);


-- =========================================================
-- 21. ADMIN CAN VIEW ALL PROFILES
-- =========================================================

create policy "Admins can view profiles"

on public.profiles

for select

to authenticated

using (
    public.is_admin()
);


-- =========================================================
-- 22. SEED ELECTION
-- =========================================================

insert into public.elections (

    title,

    description,

    status,

    starts_at,

    ends_at

)

values (

    'Student Council Election 2026',

    'College Student Council Election',

    'active',

    now(),

    now() + interval '7 days'

);


-- =========================================================
-- 23. SEED POSITIONS
-- =========================================================

insert into public.positions (

    election_id,

    name,

    max_selections

)

select

    id,

    'President',

    1

from public.elections

where title = 'Student Council Election 2026';


insert into public.positions (

    election_id,

    name,

    max_selections

)

select

    id,

    'General Secretary',

    1

from public.elections

where title = 'Student Council Election 2026';


-- =========================================================
-- 24. SEED CANDIDATES
-- =========================================================

insert into public.candidates (

    position_id,

    name,

    department,

    active

)

select

    p.id,

    candidate.name,

    candidate.department,

    true

from public.positions p

cross join (

    values

        ('Aisha Rahman', 'Computer Science'),

        ('Rohan Das', 'Information Technology'),

        ('Neha Sharma', 'Commerce')

) as candidate(name, department)

where p.name = 'President';


insert into public.candidates (

    position_id,

    name,

    department,

    active

)

select

    p.id,

    candidate.name,

    candidate.department,

    true

from public.positions p

cross join (

    values

        ('Arjun Mehta', 'Management'),

        ('Priya Nair', 'Computer Applications')

) as candidate(name, department)

where p.name = 'General Secretary';


-- =========================================================
-- 25. REALTIME
-- =========================================================

alter publication supabase_realtime
add table public.ballots;
