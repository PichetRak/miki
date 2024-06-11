import { Controller } from "@hotwired/stimulus"
import $ from 'jquery'
import DataTable from "datatables.net-bs5"
import 'datatables.net-buttons-bs5'
import 'datatables.net-buttons-html5'

// window.DataTable = DataTable();

export default class extends Controller {
  connect() {
    $(document).ready(function(){
        $('#comment-datatable').DataTable({
            processing: true,
            serverSide: true,
            paging: false,
            dom: "<<t>>",
            ajax: {
                url: $('#comment-datatable').data('source'),
                async: false,
                error: function(){
                    
                }
            },
            columns: [
                {"data": "comment"}
            ],
            // order: [[6, "desc"]],
            ordering: false,
            language: {
                zeroRecords: "No comment"
            },
            createdRow: function(row){
                // $(row).addClass("test");
            },
            fnDrawCallback: function (oSettings) {
                
            },
            destroy: true
        });

    });
  }

}