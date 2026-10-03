-- ==========================================
-- LIVE ELECTION RESULTS
-- ==========================================

create or replace function public.get_election_results(
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
set search_path = public
as $$
    select
        p.id as position_id,
        p.name as position_name,
        c.id as candidate_id,
        c.name as candidate_name,
        count(b.id) as vote_count

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
        vote_count desc,
        c.name;
$$;


revoke execute on function public.get_election_results(bigint)
from public;


grant execute on function public.get_election_results(bigint)
to authenticated;
