import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "count", "submit", "master"]

  connect() {
    this.refresh()
  }

  toggle() {
    this.refresh()
  }

  toggleAll() {
    const shouldSelectAll = !this.allSelectableChecked

    this.checkboxTargets.forEach((checkbox) => {
      if (!checkbox.disabled) {
        checkbox.checked = shouldSelectAll
      }
    })

    this.refresh()
  }

  clear() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
    })

    this.refresh()
  }

  refresh() {
    const selectedCount = this.selectedCheckboxes.length

    this.countTargets.forEach((target) => {
      target.textContent = selectedCount
    })

    this.submitTargets.forEach((target) => {
      target.disabled = selectedCount === 0
    })

    if (this.hasMasterTarget) {
      this.masterTarget.checked = this.allSelectableChecked
      this.masterTarget.indeterminate = selectedCount > 0 && !this.allSelectableChecked
    }
  }

  get selectedCheckboxes() {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked)
  }

  get selectableCheckboxes() {
    return this.checkboxTargets.filter((checkbox) => !checkbox.disabled)
  }

  get allSelectableChecked() {
    return this.selectableCheckboxes.length > 0 &&
      this.selectableCheckboxes.every((checkbox) => checkbox.checked)
  }
}
