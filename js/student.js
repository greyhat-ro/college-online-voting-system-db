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
