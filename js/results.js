async function loadResults() {

    const {
        data: { user },
        error: authError
    } = await supabaseClient.auth.getUser();


    if (authError || !user) {
        window.location.href = "login.html";
        return;
    }


    // Find the current election.
    const { data: election, error: electionError } =
        await supabaseClient
            .from("elections")
            .select("id, title, status")
            .in("status", ["active", "closed", "published"])
            .order("created_at", { ascending: false })
            .limit(1)
            .maybeSingle();


    if (electionError) {
        console.error(
            "Election loading error:",
            electionError
        );
        return;
    }


    if (!election) {
        displayMessage(
            "No election results are currently available."
        );
        return;
    }


    console.log(
        "Loading results for election:",
        election
    );


    // Call secure aggregation function.
    const { data, error } =
        await supabaseClient.rpc(
            "get_election_results",
            {
                p_election_id: election.id
            }
        );


    if (error) {
        console.error(
            "Results error:",
            error
        );
        return;
    }


    console.log(
        "Results received:",
        data
    );


    displayResults(
        election,
        data
    );
}


// ==========================================
// DISPLAY RESULTS
// ==========================================

function displayResults(
    election,
    data
) {

    const container =
        document.getElementById(
            "resultsContainer"
        );


    if (!container) {
        console.error(
            "resultsContainer not found."
        );
        return;
    }


    container.innerHTML = "";


    if (!data || data.length === 0) {

        displayMessage(
            "No votes have been recorded yet."
        );

        return;
    }


    const groupedResults = {};


    data.forEach(row => {

        if (!groupedResults[row.position_name]) {
            groupedResults[row.position_name] = [];
        }


        groupedResults[row.position_name].push(row);
    });


    Object.entries(groupedResults).forEach(
        ([position, candidates]) => {

            const section =
                document.createElement(
                    "section"
                );

            section.className = "panel";


            const heading =
                document.createElement("h2");

            heading.textContent = position;


            section.appendChild(heading);


            candidates.forEach(candidate => {

                const row =
                    document.createElement("div");

                row.className =
                    "result-row";


                row.innerHTML = `
                    <strong>
                        ${candidate.candidate_name}
                    </strong>

                    <span>
                        ${candidate.vote_count} vote(s)
                    </span>
                `;


                section.appendChild(row);
            });


            container.appendChild(section);
        }
    );
}


// ==========================================
// DISPLAY MESSAGE
// ==========================================

function displayMessage(message) {

    const container =
        document.getElementById(
            "resultsContainer"
        );


    if (!container) {
        return;
    }


    container.innerHTML = `
        <section class="panel">
            <p class="muted">
                ${message}
            </p>
        </section>
    `;
}


// ==========================================
// START
// ==========================================

loadResults();
