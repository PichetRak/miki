import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    alert("HI");
    this.element.textContent = "Hello World!"
  }
}
