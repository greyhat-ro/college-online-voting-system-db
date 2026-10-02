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
await supabaseClient.rpc(
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

//when admin adds a candidate
await supabaseClient.rpc(
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
