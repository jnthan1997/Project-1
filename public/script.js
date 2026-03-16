// script.js
document.addEventListener("DOMContentLoaded", () => {

    const loginForm = document.querySelector("#loginForm");
    if (loginForm) {
        loginForm.addEventListener("submit", (e) => {
            const email = document.querySelector("#email").value.trim();
            const password = document.querySelector("#password").value.trim();
            if (!email || !password) {
                e.preventDefault();
                alert("Please enter both email and password");
            }
        });
    }   

    const signupForm = document.querySelector("form[action='/register']");
    if (signupForm) {
        signupForm.addEventListener("submit", (e) => {
            const fname = document.querySelector("#firstname").value.trim();
            const lastname = document.querySelector("#lastname").value.trim();
            const email = document.querySelector("#email").value.trim();
            const password = document.querySelector("#password").value.trim();
            const passwordConfirm = document.querySelector("#passwordConfirm").value.trim();

            if (!fname || !lastname || !email || !password || !passwordConfirm) {
                e.preventDefault();
                alert("All fields are required");
            } else if (password !== passwordConfirm) {
                e.preventDefault();
                alert("Passwords do not match!");
            }
        });
    }

});

document.addEventListener('DOMContentLoaded', () => {
    
    const btn = document.getElementById('generateTxBtn');
    const status = document.getElementById('txStatus');

    // ONLY run this logic if the button actually exists on the current page
    if (btn && status) {
        btn.addEventListener('click', async () => {
            status.innerText = "Processing...";
            status.style.color = "black"; // Reset color

            try {
                const response = await fetch('/generate-transaction', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    'Accept': 'application/json' // Add this line!
                });

                const contentType = response.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                const rawBody = await response.text();
                console.error("Received non-JSON response:", rawBody);
                status.innerText = "Server Error: Not a JSON response.";
                return;
                }

                const data = await response.json();
                if (data.success) {
                    status.style.color = "green";
                    status.innerText = "Transaction Success!";
                } else {
                    status.style.color = "red";
                    status.innerText = "Failed to generate.";
                }
            } catch (err) {
                status.style.color = "red";
                status.innerText = "Error connecting to server.";
                console.error("Fetch error:", err);
            }
        });
    }
});