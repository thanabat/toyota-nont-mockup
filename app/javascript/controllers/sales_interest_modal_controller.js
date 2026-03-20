import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  open(event) {
    const panel = this.findPanel(event.params.key)
    if (!panel) return

    panel.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close(event) {
    const panel = event.currentTarget.closest("[data-sales-interest-modal-target='panel']")
    if (!panel) return

    panel.classList.add("hidden")
    this.releaseBodyScrollUnlessOpenPanelsRemain()
  }

  closeOnBackdrop(event) {
    if (event.target.dataset.salesInterestModalTarget === "panel") {
      event.target.classList.add("hidden")
      this.releaseBodyScrollUnlessOpenPanelsRemain()
    }
  }

  findPanel(key) {
    return this.panelTargets.find((panel) => panel.dataset.modalKeyValue === key)
  }

  releaseBodyScrollUnlessOpenPanelsRemain() {
    const hasVisiblePanel = this.panelTargets.some((panel) => !panel.classList.contains("hidden"))
    if (hasVisiblePanel) return

    document.body.classList.remove("overflow-hidden")
  }
}
