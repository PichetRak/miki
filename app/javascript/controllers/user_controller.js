import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    select_all(ev){
        let check_box_state = ev.target.checked;
        let checkbox = document.getElementsByClassName("form-check-user");
        for( let i = 0; i < checkbox.length; i++ ){
            checkbox[i].checked = check_box_state;
        }
        this.checked_select();
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

    set_id_classup(ev){
        let id = ev.target.value;
        document.getElementById("confirm-classup").value = id;
    }

    set_id_delete(ev){
        let id = ev.target.value;
        document.getElementById("btn-confirm-delete").value = id;
    }

    class_up(ev){
        let id = ev.target.value;
        if (id == ""){
            let arr_id = []
            let checkbox = document.getElementsByClassName("form-check-user");
            for( let i = 1; i < checkbox.length; i++ ){
                if (checkbox[i].checked){
                    arr_id.push(checkbox[i].value);
                }
            }
            id = arr_id
        }
        
        let url = window.location.origin+"/class_up";
        let changed_classroom = document.getElementById("change_class");
        if (!changed_classroom.value.match(/[1-6]\/[1-9]/i)){
            changed_classroom.setCustomValidity("กรุณากรอกชั้นที่ต้องการเปลี่ยน เช่น 1/1 เป็นต้น"); 
            changed_classroom.reportValidity();
        }else{
            fetch(url, {
                method: "POST", // *GET, POST, PUT, DELETE, etc.
                headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": this.getCsrfToken()
                // 'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: JSON.stringify({id: id, classroom: changed_classroom.value}), // body data type must match "Content-Type" header
            })
            .then((response) => response.text())
            .then(data => {
                // data = JSON.parse(data);
                window.location.reload();
            
            })
            .catch(error => {
                //handle error
                console.log(error);
            });
        }
    }

    delete(ev){
        let id = ev.target.value;
        if (id == ""){
            let arr_id = []
            let checkbox = document.getElementsByClassName("form-check-user");
            for( let i = 1; i < checkbox.length; i++ ){
                if (checkbox[i].checked){
                    arr_id.push(checkbox[i].value);
                }
            }
            id = arr_id
        }
        let url = window.location.origin+"/delete";
        alert(id);
        fetch(url, {
            method: "POST", // *GET, POST, PUT, DELETE, etc.
            headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.getCsrfToken()
            // 'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: JSON.stringify({id: id}), // body data type must match "Content-Type" header
        })
        .then((response) => response.text())
        .then(data => {
            // data = JSON.parse(data);
            window.location.reload();
        })
        .catch(error => {
            //handle error
            console.log(error);
        });
    }

    getCsrfToken() {
        return document.querySelector('meta[name="csrf-token"]').content;
    }
}
