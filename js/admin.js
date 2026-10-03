async function checkAdminAccess() {

    const {
        data: { user },
        error: authError
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
        window.location.href = "login.html";
        return null;
    }

    const { data: profile, error: profileError } =
        await supabaseClient
            .from("profiles")
            .select("role, full_name")
            .eq("id", user.id)
            .single();

    if (profileError || !profile) {
        console.error("Unable to verify user profile.");
        window.location.href = "index.html";
        return null;
    }

    if (profile.role !== "admin") {
        alert("Access denied. Administrator access is required.");
        window.location.href = "student.html";
        return null;
    }

    console.log("Admin authenticated:", profile.full_name);

    return {
        user,
        profile
    };
}

checkAdminAccess();

//when admin creates an election
async function createElection(electionData) {

    const { data: election, error } = await supabaseClient
        .from("elections")
        .insert(electionData)
        .select()
        .single();

    if (error) {
        console.error("Election creation failed:", error);
        return;
    }

    // Election was successfully created.
    // Now create the audit record.

    const { error: auditError } = await supabaseClient.rpc(
        "create_audit_log",
        {
            p_action: "ELECTION_CREATED",
            p_entity_type: "election",
            p_entity_id: election.id,
            p_metadata: {
                title: election.title
            }
        }
    );

    if (auditError) {
        console.error("Audit logging failed:", auditError);
    }

    console.log("Election created:", election);
}

createElection(electionData);

//when admin adds a candidate
async function addCandidate(candidateData) {

    const { data: candidate, error } = await supabaseClient
        .from("candidates")
        .insert(candidateData)
        .select()
        .single();

    if (error) {
        console.error("Candidate creation failed:", error);
        return;
    }

    const { error: auditError } = await supabaseClient.rpc(
        "create_audit_log",
        {
            p_action: "CANDIDATE_ADDED",
            p_entity_type: "candidate",
            p_entity_id: candidate.id,
            p_metadata: {
                name: candidate.name
            }
        }
    );

    if (auditError) {
        console.error("Audit logging failed:", auditError);
    }
}

addCandidate(candidateData);

//when results are published
await supabaseClient.rpc(
    "create_audit_log",
    {
        p_action: "RESULTS_PUBLISHED",
        p_entity_type: "election",
        p_entity_id: electionId,
        p_metadata: {}
    }
);
