async function logout() {

    const { error } =
        await supabaseClient.auth.signOut();

    if (!error) {
        window.location.href = "index.html";
    }
}

const logoutButton = document.getElementById("logout");

if (logoutButton) {
    logoutButton.addEventListener("click", async (event) => {
        event.preventDefault();
        await logout();
    });
}

const loginForm = document.getElementById("loginForm");

loginForm.addEventListener("submit", async (event) => {
    event.preventDefault();

    const email = document.getElementById("email").value;
    const password = document.getElementById("password").value;
    const message = document.getElementById("msg");

    message.textContent = "Signing in...";

    const { data, error } =
        await supabaseClient.auth.signInWithPassword({
            email: email,
            password: password
        });

    if (error) {
        message.textContent = error.message;
        message.className = "error";
        return;
    }

    const user = data.user;

    const { data: profile, error: profileError } =
        await supabaseClient
            .from("profiles")
            .select("role")
            .eq("id", user.id)
            .single();

    if (profileError) {
        message.textContent = "User profile not found.";
        return;
    }

    if (profile.role === "admin") {
        window.location.href = "admin.html";
    } else {
        window.location.href = "student.html";
    }
});
