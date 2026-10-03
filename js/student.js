let currentUser = null;
let currentElection = null;


// ==========================================
// 1. CHECK LOGGED-IN USER
// ==========================================

async function checkUser() {

    const {
        data: { user },
        error
    } = await supabaseClient.auth.getUser();

    if (error || !user) {
        window.location.href = "login.html";
        return false;
    }

    currentUser = user;

    console.log("Logged-in student:", currentUser.id);

    return true;
}


// ==========================================
// 2. LOAD ACTIVE ELECTION
// ==========================================

async function loadElection() {

    const { data, error } = await supabaseClient
        .from("elections")
        .select("*")
        .eq("status", "active")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

    if (error) {
        console.error("Election loading error:", error);
        return false;
    }

    if (!data) {
        console.error("No active election found.");
        alert("There is currently no active election.");
        return false;
    }

    currentElection = data;

    console.log("Active election:", currentElection);

    return true;
}


// ==========================================
// 3. LOAD POSITIONS + CANDIDATES
// ==========================================

async function loadCandidates() {

    if (!currentElection) {
        console.error("Election is not loaded.");
        return;
    }

    const { data: positions, error } =
        await supabaseClient
            .from("positions")
            .select(`
                id,
                name,
                max_selections,
                candidates (
                    id,
                    name,
                    department,
                    active
                )
            `)
            .eq("election_id", currentElection.id)
            .order("id");

    if (error) {
        console.error("Candidate loading error:", error);
        return;
    }

    console.log("Positions and candidates:", positions);

    renderCandidates(positions);
}


// ==========================================
// 4. DISPLAY CANDIDATES
// ==========================================

function renderCandidates(positions) {

    const ballot = document.getElementById("ballot");

    if (!ballot) {
        console.error("Ballot form not found.");
        return;
    }

    // Remove old candidate panels.
    // Keep this only if your ballot is dynamically generated.
    const oldPanels = ballot.querySelectorAll(".dynamic-position");

    oldPanels.forEach(panel => panel.remove());


    positions.forEach(position => {

        const section = document.createElement("section");

        section.className = "panel dynamic-position";


        const heading = document.createElement("h2");

        heading.textContent = position.name;

        section.appendChild(heading);


        const candidates =
            position.candidates.filter(candidate => candidate.active);


        candidates.forEach(candidate => {

            const label = document.createElement("label");

            label.className = "candidate";


            label.innerHTML = `
                <input
                    type="radio"
                    name="position_${position.id}"
                    value="${candidate.id}"
                    data-position-id="${position.id}"
                    required
                >

                <span>
                    <b>${candidate.name}</b>
                    <small>${candidate.department || ""}</small>
                </span>
            `;


            section.appendChild(label);
        });


        ballot.insertBefore(
            section,
            ballot.querySelector(".btn")
        );
    });
}


// ==========================================
// 5. SUBMIT VOTE
// ==========================================

async function submitVote(event) {

    event.preventDefault();

    if (!currentUser) {
        alert("Please log in again.");
        return;
    }

    if (!currentElection) {
        alert("No active election found.");
        return;
    }


    const ballot =
        document.getElementById("ballot");

    if (!ballot) {
        return;
    }


    const selected =
        ballot.querySelectorAll(
            'input[type="radio"]:checked'
        );


    if (selected.length === 0) {
        alert("Please select your candidates.");
        return;
    }


    const submitButton =
        ballot.querySelector(".btn");

    if (submitButton) {
        submitButton.disabled = true;
        submitButton.textContent = "Submitting...";
    }


    try {

        // Submit one ballot for each selected position.
        for (const input of selected) {

            const candidateId =
                Number(input.value);

            const positionId =
                Number(input.dataset.positionId);


            const { data: ballotRow, error } =
                await supabaseClient
                    .from("ballots")
                    .insert({
                        election_id: currentElection.id,
                        voter_id: currentUser.id,
                        candidate_id: candidateId,
                        position_id: positionId
                    })
                    .select()
                    .single();


            if (error) {
                console.error(
                    "Vote insertion error:",
                    error
                );

                throw error;
            }


            console.log(
                "Vote successfully recorded:",
                ballotRow
            );


            // Audit the successful vote.
            const { error: auditError } =
                await supabaseClient.rpc(
                    "create_audit_log",
                    {
                        p_action: "VOTE_SUBMITTED",
                        p_entity_type: "ballot",
                        p_entity_id: String(ballotRow.id),
                        p_metadata: {
                            election_id:
                                currentElection.id,

                            position_id:
                                positionId
                        }
                    }
                );


            if (auditError) {

                console.error(
                    "Audit logging error:",
                    auditError
                );

                // We do NOT cancel the vote here.
                // The vote has already been recorded.
            }
        }


        alert("Your vote has been submitted successfully.");

        ballot.reset();


        if (submitButton) {
            submitButton.disabled = false;
            submitButton.textContent = "Submit Vote";
        }

        // Optional: redirect to results.
        window.location.href = "results.html";


    } catch (error) {

        console.error("Vote submission failed:", error);

        alert(
            "Your vote could not be submitted.\n\n" +
            "Please check the browser console for details."
        );


        if (submitButton) {
            submitButton.disabled = false;
            submitButton.textContent = "Submit Vote";
        }
    }
}


// ==========================================
// 6. INITIALIZE STUDENT PAGE
// ==========================================

async function initializeStudentPage() {

    const authenticated =
        await checkUser();

    if (!authenticated) {
        return;
    }


    const electionLoaded =
        await loadElection();

    if (!electionLoaded) {
        return;
    }


    await loadCandidates();


    const ballot =
        document.getElementById("ballot");


    if (ballot) {

        ballot.addEventListener(
            "submit",
            submitVote
        );
    }
}


// Start application.
initializeStudentPage();


/*
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
*/
