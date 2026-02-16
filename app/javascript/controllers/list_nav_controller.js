import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static classes = ["active", "inactive", "activeText", "inactiveText"]

  itemTargetConnected(item) {
    if (item.classList.contains("bg-primary/20")) {
      this.#activate(item)
    }
  }

  select(event) {
    const clicked = event.target.closest("[data-list-nav-target='item']")
    if (!clicked) return

    // Close sidebar on mobile
    const sidebar = document.querySelector("[data-controller='sidebar']")
    if (sidebar && window.innerWidth < 768) {
      const panel = sidebar.querySelector("[data-sidebar-target='panel']")
      const overlay = sidebar.querySelector("[data-sidebar-target='overlay']")
      if (panel) panel.classList.add("-translate-x-full")
      if (overlay) overlay.classList.add("hidden")
    }

    this.#activate(clicked)
  }

  #activate(active) {
    this.itemTargets.forEach(item => {
      const link = item.querySelector("[data-list-link]")

      if (item === active) {
        item.classList.add("bg-primary/20", "border-primary")
        item.classList.remove("border-transparent")
        if (link) {
          link.classList.add("text-white", "font-semibold")
          link.classList.remove("text-gray-300")
        }
      } else {
        item.classList.remove("bg-primary/20", "border-primary")
        item.classList.add("border-transparent")
        if (link) {
          link.classList.remove("text-white", "font-semibold")
          link.classList.add("text-gray-300")
        }
      }
    })
  }
}
