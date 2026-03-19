import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "remaining", "warning", "submit"]

  connect() {
    this.refresh()
  }

  refresh() {
    let hasInvalidInput = false

    this.inputTargets.forEach((input) => {
      const rowId = input.dataset.rowId
      const availableQuantity = Number.parseInt(input.dataset.availableQuantity, 10)
      const selectedQuantity = Number.parseInt(input.value, 10)
      const remainingTarget = this.remainingTargets.find((target) => target.dataset.rowId === rowId)
      const warningTarget = this.warningTargets.find((target) => target.dataset.rowId === rowId)

      let warningMessage = ""
      let remainingQuantity = availableQuantity

      if (Number.isNaN(selectedQuantity) || selectedQuantity < 1) {
        hasInvalidInput = true
        warningMessage = "กรุณากรอกจำนวนอย่างน้อย 1"
      } else if (selectedQuantity > availableQuantity) {
        hasInvalidInput = true
        remainingQuantity = availableQuantity - selectedQuantity
        warningMessage = "จำนวนที่สั่งเกิน Qty ที่มี"
      } else {
        remainingQuantity = availableQuantity - selectedQuantity
      }

      if (remainingTarget) {
        remainingTarget.textContent = remainingQuantity
        remainingTarget.classList.toggle("text-rose-700", warningMessage.length > 0)
        remainingTarget.classList.toggle("text-stone-900", warningMessage.length === 0)
      }

      if (warningTarget) {
        warningTarget.textContent = warningMessage
        warningTarget.classList.toggle("hidden", warningMessage.length === 0)
      }
    })

    this.submitTargets.forEach((target) => {
      target.disabled = hasInvalidInput
    })
  }
}
