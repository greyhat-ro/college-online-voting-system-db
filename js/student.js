async function checkUser() {

    const {
        data: { user }
    } = await supabaseClient.auth.getUser();

    if (!user) {
        window.location.href = "login.html";
        return null;
    }

    return user;
}

checkUser();

async function loadElection() {

    const { data, error } = await supabaseClient
        .from("elections")
        .select("*")
        .eq("status", "active")
        .limit(1)
        .single();

    if (error) {
        console.error(error);
        return;
    }

    console.log(data);
}

loadElection();

async function loadCandidates() {
    // Get positions and candidates
    const { data: positions, error } =
    await supabaseClient
        .from("positions")
        .select(`
            id,
            name,
            candidates (
                id,
                name,
                department
            )
        `)
        .eq("election_id", election.id);
}

loadCandidates();

async function submitVote() {
    // Get logged-in student
    // Get selected candidates
    // Insert votes into Supabase
    const { data, error } = await supabaseClient
    .from("ballots")
    .insert({
        election_id: electionId,
        voter_id: user.id,
        candidate_id: candidateId,
        position_id: positionId
    });
}

submitVote();

await supabaseClient.rpc(
    "create_audit_log",
    {
        p_action: "VOTE_SUBMITTED",
        p_entity_type: "ballot",
        p_entity_id: null,
        p_metadata: {
            election_id: electionId,
            position_id: positionId
        }
    }
);
