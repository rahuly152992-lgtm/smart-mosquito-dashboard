document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("form[action='/login']");
  if (!form) return;

  form.addEventListener("submit", (event) => {
    const username = form.querySelector("[name='username']");
    const password = form.querySelector("[name='password']");

    if (!username.value.trim() || !password.value) {
      event.preventDefault();
      form.reportValidity();
    }
  });
});