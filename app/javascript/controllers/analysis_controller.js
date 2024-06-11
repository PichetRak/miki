import { Controller } from "@hotwired/stimulus"
import $ from 'jquery'
import DataTable from "datatables.net-bs5"
import 'datatables.net-buttons-bs5'
import 'datatables.net-buttons-html5'

// window.DataTable = DataTable();

export default class extends Controller {
  connect() {}

  today(){
    let btn_today = document.getElementById("graph-btn-today");
    let btn_week = document.getElementById("graph-btn-week");
    let btn_month = document.getElementById("graph-btn-month");
    let selected_user = document.getElementById("selected_user");
    if (!btn_today.classList.contains('active')){
      btn_week.classList.remove("active");
      btn_month.classList.remove("active");
      btn_today.classList.add("active");
      this.ajax_call("today", selected_user.value);
    }
  }

  week(){
    let btn_today = document.getElementById("graph-btn-today");
    let btn_week = document.getElementById("graph-btn-week");
    let btn_month = document.getElementById("graph-btn-month");
    let selected_user = document.getElementById("selected_user");
    if (!btn_week.classList.contains('active')){
      btn_week.classList.add("active");
      btn_month.classList.remove("active");
      btn_today.classList.remove("active");
      this.ajax_call("week", selected_user.value);
    }
  }

  month(){
    let btn_today = document.getElementById("graph-btn-today");
    let btn_week = document.getElementById("graph-btn-week");
    let btn_month = document.getElementById("graph-btn-month");
    let selected_user = document.getElementById("selected_user");
    if (!btn_month.classList.contains('active')){
      btn_week.classList.remove("active");
      btn_month.classList.add("active");
      btn_today.classList.remove("active");
      this.ajax_call("month", selected_user.value);
    }
  }

  selected_student(ev){
    // let selected_user = document.getElementById("selected_user");
    let user_id = ev.target.value;
    let btn_today = document.getElementById("graph-btn-today");
    let btn_week = document.getElementById("graph-btn-week");
    let btn_month = document.getElementById("graph-btn-month");
    btn_week.classList.remove("active");
    btn_month.classList.remove("active");
    btn_today.classList.add("active");
    this.ajax_call("today", user_id);
    let student_name = ev.target.parentNode.parentNode.getElementsByClassName("table-student-name");
    // let student_name = document.querySelectorAll('.student-list[value="'+user_id+'"]');
    let result = document.getElementById("analysis_result");
    let analyze_result = result.value.split(",");
    $("#div-analysis-result").html('');
    let analyze_html = '<h6 class="text-student">ชื่อ-นามสกุล: '+student_name[0].innerText+', </h6><h6>ผลการวิเคราะห์ :</h6><h6 class="result-'+analyze_result[0]+'">'+analyze_result[1]+'</h6>'
    $("#div-analysis-result").html(analyze_html);
    document.getElementById("selected_user").value = user_id
    // $(".btn-close").click();
    // selected_user.value = user_id;
  }

  ajax_call(type, user_id = null){
    $.ajax({
      url: "/analysis_depression/range",
      type: "GET",
      async: false,
      data: { 
        selected_type: type,
        selected_id: user_id
      },
      // dataType: "JSON",
      success: function(data){
        $("#line-graph").html('');
        $("#line-graph").html(data);
        // let div_graph = document.getElementById("line-graph");
        // div_graph.innerHTML = '';
        // div_graph.innerHTML = data;
      },
      error: function(xhr, error, thrown){
         
      }
    });
  }
}