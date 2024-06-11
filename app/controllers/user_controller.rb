class UserController < ApplicationController
    def index
        classroom = session["current_user"]["classroom"]
        @user = User.where(classroom: classroom, status: "active", role: 2).order(personal_id: :asc)
        if session["current_user"]["role"] == 0
            classroom = User.select(:classroom).group(:classroom)
            h_classroom = classroom.index_by(&:classroom)
            @all_classroom = h_classroom.keys
        end
    end

    def select_class_for_admin
        classroom = params[:classroom]
        @user = User.where(classroom: classroom, status: "active", role: 2).order(personal_id: :asc)
        render partial: "table"
    end

    def class_up
        classroom = params["classroom"]
        if (params["id"].kind_of? Array)
            arr_id = params["id"]
            arr_id.each{ |id| User.update(id, classroom: classroom) }
        else
            id = params["id"]
        end
        
        respond_to do |format|
            format.json { render json: {} }
        end
    end

    def delete
        if (params["id"].kind_of? Array)
            arr_id = params["id"]
            arr_id.each{ |id| User.update(id, status: "deleted") }
        else
            id = params["id"]
            User.update(id, status: "deleted")
        end

        respond_to do |format|
            format.json { render json: {} }
        end
    end
end
