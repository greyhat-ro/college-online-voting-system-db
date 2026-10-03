-- ==========================================
-- STUDENT READ ACCESS
-- ==========================================

-- Remove existing versions first

drop policy if exists "Authenticated users can view active elections"
on public.elections;

drop policy if exists "Authenticated users can view positions"
on public.positions;

drop policy if exists "Authenticated users can view active candidates"
on public.candidates;

drop policy if exists "Students can submit their own ballots"
on public.ballots;

drop policy if exists "Users can view their own profile"
on public.profiles;


-- ==========================================
-- PROFILES
-- ==========================================

create policy "Users can view their own profile"
on public.profiles
for select
to authenticated
using (
    id = auth.uid()
);


-- ==========================================
-- ELECTIONS
-- ==========================================

create policy "Authenticated users can view active elections"
on public.elections
for select
to authenticated
using (
    status = 'active'
);


-- ==========================================
-- POSITIONS
-- ==========================================

create policy "Authenticated users can view positions"
on public.positions
for select
to authenticated
using (
    exists (
        select 1
        from public.elections e
        where e.id = positions.election_id
        and e.status = 'active'
    )
);


-- ==========================================
-- CANDIDATES
-- ==========================================

create policy "Authenticated users can view active candidates"
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
        and e.status = 'active'
    )
);


-- ==========================================
-- BALLOTS
-- ==========================================

create policy "Students can submit their own ballots"
on public.ballots
for insert
to authenticated
with check (

    voter_id = auth.uid()

    and exists (
        select 1
        from public.elections e
        where e.id = ballots.election_id
        and e.status = 'active'
    )

    and exists (
        select 1
        from public.positions p
        where p.id = ballots.position_id
        and p.election_id = ballots.election_id
    )

    and exists (
        select 1
        from public.candidates c
        where c.id = ballots.candidate_id
        and c.position_id = ballots.position_id
        and c.active = true
    )
);
