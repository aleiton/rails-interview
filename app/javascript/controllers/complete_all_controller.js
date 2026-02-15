import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["button", "progressContainer", "progressBar", "progressText"]
  static values = { listId: Number, listSlug: String }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TodoListChannel", id: this.listIdValue },
      { received: (data) => this.handleMessage(data) }
    )
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    if (this.consumer) this.consumer.disconnect()
  }

  start() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(`/todolists/${this.listSlugValue}/complete_all`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })

    if (this.hasButtonTarget) this.buttonTarget.classList.add("hidden")
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.classList.remove("hidden")
      this.progressTextTarget.textContent = "Starting..."
    }
  }

  handleMessage(data) {
    switch (data.action) {
      case "progress":
        this.updateProgress(data)
        this.markItemsCompleted(data.completed_ids || [])
        break
      case "completed":
        this.updateProgress(data)
        this.progressTextTarget.textContent = `Done! ${data.completed}/${data.total} completed`
        setTimeout(() => {
          const frame = document.getElementById("main_content")
          if (frame) frame.src = window.location.pathname
        }, 1500)
        break
      case "error":
        if (this.hasProgressTextTarget) {
          this.progressTextTarget.textContent = "An error occurred"
        }
        if (this.hasProgressBarTarget) {
          this.progressBarTarget.classList.remove("bg-green")
          this.progressBarTarget.classList.add("bg-coral")
        }
        break
    }
  }

  updateProgress(data) {
    if (data.total > 0) {
      const percentage = Math.round((data.completed / data.total) * 100)
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = `${percentage}%`
      }
      if (this.hasProgressTextTarget) {
        this.progressTextTarget.textContent = `${data.completed} of ${data.total} items completed (${percentage}%)`
      }
    }
  }

  markItemsCompleted(ids) {
    ids.forEach(id => {
      const itemEl = document.getElementById(`todo_item_${id}`)
      if (!itemEl) return

      const checkbox = itemEl.querySelector("[data-checkbox]")
      if (checkbox) {
        checkbox.className = "w-5 h-5 rounded border-2 flex items-center justify-center bg-green border-green"
        checkbox.innerHTML = '<svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/></svg>'
      }

      const text = itemEl.querySelector("[data-description]")
      if (text) {
        text.classList.add("line-through", "text-gray-400")
        text.classList.remove("text-gray-800")
      }
    })
  }
}
