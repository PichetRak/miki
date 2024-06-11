import { Controller } from "@hotwired/stimulus"
import $ from 'jquery'
import DataTable from "datatables.net-bs5"
import 'datatables.net-buttons-bs5'
import 'datatables.net-buttons-html5'

import jQuery from "jquery"
import "select2"

export default class extends Controller {
    connect() {
        $(document).ready(function(){
            $('#forum-datatable').DataTable({
                processing: true,
                serverSide: true,
                paging: true,
                pagingType: "simple_numbers",
                pageLength: 20,
                dom: "<<t>p>",
                ajax: {
                    url: $('#forum-datatable').data('source'),
                    async: false,
                    data: {
                        
                    },
                    error: function(){
                        
                    }
                },
                columns: [
                    {"data": "question"}
                ],
                ordering: false,
                language: {
                    paginate: {
                        previous: '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" class="bi bi-chevron-left" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/></svg>',
                        next: '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" class="bi bi-chevron-right" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/></svg>'
                    },
                    zeroRecords: "No question"
                },
                createdRow: function(row){
                    // $(row).addClass("test");
                },
                fnDrawCallback: function (oSettings) {
                    
                },
                destroy: true
            });

            $("#select-multi-tag").select2();

        });
    }

    create(){
        let button = document.getElementById("btn-create-question");
        button.style.display = "none";
    }

    cancel(){
        let text_area = document.getElementById("question_question");
        text_area.value = "";
        let button = document.getElementById("btn-create-question");
        button.style.display = "block";
    }

    filter(){
        let arr_btn = document.getElementsByClassName("btn-tag-filter");
        let active_filter = []
        for( let i=0; i < arr_btn.length; i++){
            if (arr_btn[i].classList.contains('active')){
                active_filter.push(parseInt(arr_btn[i].value));
            }
            
        }
        this.table_properties(active_filter);
    }

    table_properties(arr_filter=[]){
        let table = $('#forum-datatable').DataTable({
            processing: true,
            serverSide: true,
            paging: true,
            pagingType: "simple_numbers",
            pageLength: 20,
            dom: "<<t>p>",
            ajax: {
                url: $('#forum-datatable').data('source'),
                async: false,
                data: {
                    tag: arr_filter
                },
                error: function(){
                    
                }
            },
            columns: [
                {"data": "question"}
            ],
            ordering: false,
            language: {
                paginate: {
                    previous: '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" class="bi bi-chevron-left" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/></svg>',
                    next: '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" class="bi bi-chevron-right" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/></svg>'
                },
                zeroRecords: "No question"
            },
            createdRow: function(row){
                // $(row).addClass("test");
            },
            fnDrawCallback: function (oSettings) {
                
            },
            destroy: true
        });

        table.draw();

    }

}