class DepressionAnalysisController < ApplicationController
    def index
        today = DateTime.now()
        user_id = session["current_user"]["id"]
        depression = Depression.where(user_id: user_id, date: today.strftime("%Y-%m-%d")).limit(1)
        
        @data = default_value
        @risk_result = ["default", "ไม่มีความเสี่ยง"]
        @is_today = true
        if depression.present?
            depression = depression.first
            json_depression = JSON.parse(depression.depression.to_json)
            json_depression.each { |k, v| @data[0][k] = v.length }

            score = analysis_score(json_depression, user_id)
            
            @risk_result = analysed_result(score)
        end
        @data = @data[0].to_a
        @current_user = session["current_user"]

        #### For admin or Teacher ####
        if session["current_user"]["role"] != 2
            @user = User.where(role: 2)
            @user = @user.where(classroom: session["current_user"]["classroom"]) if session["current_user"]["role"] == 1
            @user = @user.order(personal_id: :ASC)

            @risk_student_result = Hash.new
            student_dpression = Depression.where(user_id: @user.pluck(:id), date: today.strftime("%Y-%m-%d"))
            student_dpression.each do |st|
                json_depression = JSON.parse(st.depression.to_json)
                json_depression.each { |k, v| @data[0][k] = v.length }
    
                score = analysis_score(json_depression, st.user_id)
                @risk_student_result[(st.user.id).to_s] = analysed_result(score)
            end
        end
    end

    def range
        type = params["selected_type"]
        user_id = params["selected_id"].present? ? params["selected_id"] : session["current_user"]["id"]
        date = DateTime.now()
        dp = Depression.where(user_id: user_id)
        @risk_result = ["default", "ไม่มีความเสี่ยง"]
        case type
        when "today"
            today = date.strftime("%Y-%m-%d")
            @data = default_value
            dp = dp.where(date: today).limit(1)
            if dp.present?
                dp = dp.first
                json_depression = JSON.parse(dp.depression.to_json)
                json_depression.each { |k, v| @data[0][k] = v.length }
                
                score = analysis_score(json_depression, user_id)
                @risk_result = analysed_result(score)
            end
            @data = @data[0].to_a
            @is_today = true
        when "week"
            week = date.beginning_of_week(:monday).strftime("%Y-%m-%d")
            end_week = date.end_of_week(:monday).strftime("%Y-%m-%d")
            dp = dp.where("date between ? and ? ", week, end_week)
            if dp.present?
                hash_dp = dp.index_by{ |d| d.date.strftime("%Y-%m-%d") }
                @data = set_data_range(hash_dp, week, end_week)
            else
                @data = default_range(week, end_week)
            end
            @is_today = false
        when "month"
            beginning_of_month = date.at_beginning_of_month.strftime("%Y-%m-%d")
            end_of_month = date.at_end_of_month.strftime("%Y-%m-%d")
            dp = dp.where("date between ? and ? ", beginning_of_month, end_of_month)
            if dp.present?
                hash_dp = dp.index_by{ |d| d.date.strftime("%Y-%m-%d") }
                @data = set_data_range(hash_dp, beginning_of_month, end_of_month)
            else
                @data = default_range(beginning_of_month, end_of_month)
            end
            @is_today = false
        else
            @data = {}
        end

        render partial: "graph"
    end

    private
    def default_key
        arr_keys = ["เบื่อ", "ท้อแท้", "ปัญหาการนอน", "เหนื่อย", "เบื่ออาหาร", "กระวนกระวาย", "รู้สึกไร้ค่า", "สมาธิสั้น", "อยากฆ่าตัวตาย"]
        arr_keys
    end

    def set_data_range db_depression, start_date, end_date
        h_depression = Hash.new()
        keys = default_key
        (start_date..end_date).each do |date|
            if db_depression[date].present?
                depression = db_depression[date].depression
                keys.each do |k|
                    h_depression[k] ||= []
                    count = depression[k].present? ? depression[k].length : 0
                    h_depression[k] << [date, count]
                end
            else
                keys.each do |k|
                    h_depression[k] ||= []
                    h_depression[k] << [date, 0]
                end
            end
        end
        h_depression
    end

    def default_value
        h_depression = []
        h_depression << {"เบื่อ" => 0,
                        "ท้อแท้" => 0,
                        "ปัญหาการนอน" => 0,
                        "เหนื่อย" => 0,
                        "เบื่ออาหาร" => 0,
                        "กระวนกระวาย" => 0,
                        "รู้สึกไร้ค่า" => 0,
                        "สมาชิกสั้น" => 0,
                        "อยากฆ่าตัวตาย" => 0}
        h_depression
    end

    def default_range s_date, e_date
        start_date = Date.parse(s_date)
        end_date = Date.parse(e_date)
        keys = default_key
        h_depression = Hash.new()
        (start_date..end_date).each do |date|
            keys.each do |k|
                h_depression[k] ||= []
                h_depression[k] << [date, 0]
            end
        end
        h_depression
    end

    def analysis_score json_depression, user_id
        score = 0
        ## case: 1 have despression words more than 5
        score += 1 if json_depression.keys.length >= 5

        ## case: 2 have word "เบื่อ", "ท้อแท้"
        score += 1 if json_depression.keys.include?("เบื่อ") || json_depression.keys.include?("ท้อแท้")

        ## case: 3 have depression words since 2 week agos
        two_week_agos = Time.now - (2*7*24*60*60)
        dp_of_2_weeks = Depression.where(user_id: user_id).where("date between ? and ? ", two_week_agos.strftime("%Y-%m-%d"), Date.yesterday.strftime("%Y-%m-%d"))
        have_every_day = 0
        dp_of_2_weeks.each do |dp| 
            if dp.depression.present?
                have_every_day += 1 if dp.depression.keys.length > 1
            end
        end
        score += 1 if have_every_day >= 10
        score
    end

    def analysed_result score
        result = case score
                when 1 then ["no-risk", "ความเสี่ยงต่ำ"]
                when 2 then ["medium", "ค่อนข้างเสี่ยง"]
                when 3 then ["risk", "ความเสี่ยงสูง ควรปรึกษาคุณครูหรือพบแพทย์"]
                else ["default", "ไม่มีความเสี่ยง"]
                end
        result
    end
end
