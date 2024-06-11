import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["classroom"]
  connect() {
    // const select_classroom = this.classroomTarget;
    // let text = select_classroom.options[select_classroom.selectedIndex].text;
    // alert(text);
  }

  change_classroom(){
    const select_classroom = this.classroomTarget;
    let text = select_classroom.options[select_classroom.selectedIndex].text;

    let url = window.location.origin+"/select_class";
    fetch(url, {
        method: "POST", // *GET, POST, PUT, DELETE, etc.
        headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCsrfToken()
        // 'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: JSON.stringify({classroom: text}), // body data type must match "Content-Type" header
    })
    .then((response) => response.text())
    .then(data => {
        // console.log(document.getElementById("div-table-user-list").innerHTML);
        document.getElementById("div-table-user-list").innerHTML = data;
        this.checked_select()
        // data = JSON.parse(data);
        // window.location.reload();
    })
    .catch(error => {
        //handle error
        console.log(error);
    });
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }

  checked_select(){
    let checkbox = document.querySelectorAll('.form-check-user:checked');
    if (checkbox.length > 0){
        document.getElementById("div-btn-all-action").classList.add("d-inline-flex");
        document.getElementById("div-btn-all-action").classList.remove("d-none");
    }else{
        document.getElementById("div-btn-all-action").classList.remove("d-inline-flex");
        document.getElementById("div-btn-all-action").classList.add("d-none");
    }
}
}
