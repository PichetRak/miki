import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    var is_error = this.element.classList.contains("alert-danger");
    if (is_error){
      setTimeout(this.flash_message_timeout, 10000);
    }else{
      setTimeout(this.flash_message_timeout, 5000);
    }
  }

  flash_message_timeout(){
    const fadeEffect = setInterval(function () {
      let div_alert = document.getElementsByClassName("div-alert");
      let opacity = Number(window.getComputedStyle(div_alert[0]).getPropertyValue("opacity"));
      
      if (div_alert[0].style.opacity > 0) {
        opacity -= 0.1;
        div_alert[0].style.opacity = opacity;
      } else {
        clearInterval(fadeEffect);
        div_alert[0].style.cssText += "display: none !important";
      }
    }, 20);
  }
}
