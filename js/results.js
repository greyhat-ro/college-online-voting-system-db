async function loadResults() {

    const {
        data: { user },
        error: authError
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
        window.location.href = "login.html";
        return;
    }


    const { data, error } = await supabaseClient
        .from("ballots")
        .select(`
            candidate_id,
            candidates (
                id,
                name,
                position_id,
                positions (
                    name
                )
            )
        `);

    if (error) {
        console.error("Results error:", error);
        return;
    }


    const results = {};

    data.forEach(vote => {

        const candidate = vote.candidates;

        if (!candidate) {
            return;
        }

        const positionName =
            candidate.positions?.name || "Unknown Position";

        const candidateName =
            candidate.name;

        if (!results[positionName]) {
            results[positionName] = {};
        }

        if (!results[positionName][candidateName]) {
            results[positionName][candidateName] = 0;
        }

        results[positionName][candidateName]++;
    });


    displayResults(results);
}


function displayResults(results) {

    const container =
        document.getElementById("resultsContainer");

    if (!container) {
        return;
    }

    container.innerHTML = "";

    Object.entries(results).forEach(
        ([position, candidates]) => {

            const section =
                document.createElement("section");

            section.className = "panel";

            const heading =
                document.createElement("h2");

            heading.textContent = position;

            section.appendChild(heading);


            Object.entries(candidates).forEach(
                ([candidate, votes]) => {

                    const row =
                        document.createElement("div");

                    row.className = "result-row";

                    row.innerHTML = `
                        <strong>${candidate}</strong>
                        <span>${votes} vote(s)</span>
                    `;

                    section.appendChild(row);
                }
            );

            container.appendChild(section);
        }
    );
}


loadResults();
