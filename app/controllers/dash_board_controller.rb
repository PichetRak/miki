class DashBoardController < ApplicationController
    include DashBoardHelper

    def index
        return redirect_to login_path() if session["current_user"].blank?
        @first_login = session["current_user"]["first_login"]
        student_id = session["current_user"]["personal_id"]
        session[student_id] = Hash.new()
        session[student_id]["is_new_intent"] = true
        session["state"] = "main"
        session["survey_count"] = 0
        # session["prompt_txt"] = read_json("./lib/prompt_text.json")
        @user = User.new()
    end

    def analyzed
        today = DateTime.now().strftime("%Y-%m-%d")
        user_id = session["current_user"]["id"]

        result = call_dialog_flow(session, params[:record_audio])
        result = result.deep_symbolize_keys
        if result.dig(:keywords, :depression_symptoms).present?
            dp = Depression.where(user_id: user_id, date: today).limit(1)

            if dp.present?
                #update
                depression = dp.first
                json_depression = depression.depression
                update_json_dp = set_depression_value(json_depression, result)
                Depression.update(depression.id, depression: update_json_dp)
            else
                #create
                json_depression = Hash.new
                update_json_dp = set_depression_value(json_depression, result)
                Depression.create(user_id: user_id, date: today, depression: update_json_dp, status: 1)
            end
        end

        respond_to do |format|
            format.json { render :json => result.to_json }
        end
    end

    def count_stress_rate
        
    end

    def send_notification
        user = User.find(2)
        NotificationDepressionMailer.send_notification(user).deliver_now
        redirect_to root_path()
    end

    private
    def set_depression_value json_dep, result
        result[:keywords][:depression_symptoms].each do |k|
            key = case k
                when "เบื่อ", "เครียด", "หงุดหงิด" then "เบื่อ"
                when "รู้สึกแย่", "ท้อ", "ไม่มีความสุข" then "ท้อแท้"
                when "พักผ่อนไม่เพียงพอ" then "ปัญหาการนอนหลับ"
                when "สมาธิสั้น", "ความจำสั้น" then "สมาธิสั้น"
                when "ฆ่าตัวตาย", "ทำร้ายตัวเอง", "ตาย" then "อยากฆ่าตัวตาย"
                else k
                end
            json_dep[key] ||= []
            json_dep[key] << result[:recognite_txt]
            json_dep[key].uniq!
        end
        json_dep
    end

end
