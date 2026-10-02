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
