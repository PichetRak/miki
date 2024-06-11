import { Application } from "@hotwired/stimulus"
import $ from 'jquery'
import DataTable from "datatables.net-bs5"
import 'datatables.net-buttons-bs5'
import 'datatables.net-buttons-html5'
import jQuery from "jquery"
window.jQuery = jQuery // <- "select2" will check this
window.$ = jQuery

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }