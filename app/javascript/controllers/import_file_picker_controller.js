import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName", "submit"]
  static values = { submitOnSelect: Boolean }

  connect() {
    this.updateState()
  }

  browse() {
    this.inputTarget.click()
  }

  selected() {
    this.updateState()

    if (this.submitOnSelectValue && this.inputTarget.files[0]) {
      this.element.requestSubmit()
    }
  }

  updateState() {
    const file = this.inputTarget.files[0]

    if (file) {
      this.fileNameTarget.textContent = file.name
      this.fileNameTarget.classList.remove("text-stone-500")
      this.fileNameTarget.classList.add("text-stone-900")
    } else {
      this.fileNameTarget.textContent = "ยังไม่ได้เลือกไฟล์"
      this.fileNameTarget.classList.remove("text-stone-900")
      this.fileNameTarget.classList.add("text-stone-500")
    }
  }
}
