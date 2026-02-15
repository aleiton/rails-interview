import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]
  static values = { url: String, field: String }

  edit() {
    if (!this.hasFormTarget) return

    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  save(event) {
    event.preventDefault()

    const value = this.inputTarget.value.trim()
    if (value === "") {
      this.cancel()
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const body = new FormData()
    body.append(this.fieldValue, value)
    body.append("_method", "PATCH")

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken
      },
      body: body
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
    .catch(() => this.cancel())
  }

  cancel() {
    if (!this.hasFormTarget) return

    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }
}
