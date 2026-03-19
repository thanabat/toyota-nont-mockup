import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "label", "button"]
  static values = { message: String }

  start() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("hidden")
    }

    if (this.hasLabelTarget && this.hasMessageValue) {
      this.labelTarget.textContent = this.messageValue
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  reset() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add("hidden")
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
    }
  }
}
