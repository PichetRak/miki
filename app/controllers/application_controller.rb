class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session
    helper_method :is_logged_in?
    # add_flash_types :info, :error, :warning, :success
    require 'net/http'
    require 'uri'
    require 'json'
    require 'google/cloud/dialogflow'
    require 'date'
    require 'time'
    include ApplicationHelper

    def is_logged_in?
        return redirect_to login_path() if session["current_user"].blank?
    end

    def analyzed
        # call_dialog_flow(session, params[:record_audio])
    end
end
