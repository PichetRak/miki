module DashBoardHelper
    CREDENTIALS_PATH = "./lib/depression-therapy-a9ok-854d46e86d91.json"
    PROJECT_ID = "depression-therapy-a9ok"

    def config_dialog_flow
        Google::Cloud::Dialogflow.sessions do |config|
            config.credentials = CREDENTIALS_PATH
            config.timeout = 10.0
        end
    end

    def call_dialog_flow session, file
        begin
            student_id = session["current_user"]["personal_id"]
            ##### Audio file #####
            client = config_dialog_flow

            # Send requests on the stream
            create_session = generate_client_session(session)
            request_stream = {
                session: create_session,
                query_input: {
                    audio_config: {
                        audio_encoding: Google::Cloud::Dialogflow::V2::AudioEncoding::AUDIO_ENCODING_LINEAR_16,
                        # sample_rate_hertz: 48000,
                        language_code: "th-TH"
                    }
                },
                input_audio: File.read(file.tempfile, mode: "rb")
            }

            response = client.detect_intent request_stream

            query_result = response.query_result
            recognite_txt, intention = nil
            if query_result.query_text.present?
                keywords = Hash.new
                recognite_txt = query_result.query_text
                intention = query_result.intent.display_name
                query_result.parameters.fields.each do |k, v|
                    keywords[k] = []
                    if v.list_value.present?
                        v.list_value.values.each{ |val| keywords[k] << val.string_value }
                    else
                        keywords[k] << v.string_value
                    end
                end

                session[student_id]["recognite_txt"] = recognite_txt

                case session["state"]
                when "main"
                    session[student_id]["intent"] = intention
                    session[student_id]["keyword"] = keywords
                    prompts = main_dialog(session, student_id)

                when "confirm"
                    prompts = confirm_dialog(session, student_id, intention)
                when "survey"
                    prompts = survey_random_question(session, student_id, intention)
                    prompts.flatten!
                end

                if prompts.blank?
                    prompts = get_default_prompt(intention)
                    session[student_id]["is_new_intent"] = true
                end
                
            else
                ## Timeout
                prompts = ["retry1.wav"]
                if session["state"] == "survey"
                    prompts = survey_random_question(session, student_id, intention)
                    prompts.flatten!
                end
            end
        rescue => e
            p e.message
            p e.backtrace
            prompts = ["retry1.wav"]
        end

        result = {
            "prompts": prompts,
            "prompt_script": get_prompt_script(prompts),
            "recognite_txt": recognite_txt,
            "intent": intention,
            # confidence: query_result.intent_detection_confidence,
            # response_txt: query_result.fulfillment_text,
            "keywords": keywords,
        }

        result

        ##### Text Input
        # client = config_dialog_flow
        # create_session = generate_client_session(session)
        # query = { text: { text: "เบื่อ", language_code: "th-TH" } }

        # # Session and query are keyword arguments
        # response = client.detect_intent session: create_session, query_input: query
        # p response
    end

    private
    def generate_client_session session
        uniq_id = session["current_user"]["personal_id"].to_s + session["current_user"]["id"].to_s
        return "projects/#{PROJECT_ID}/agent/sessions/#{uniq_id}"
    end

    def main_dialog session, student_id
        session["state"] = "main"
        if session[student_id]["intent"] == "welcome_intent"
            random_greeting = (1..5).to_a.sample(1)
            kw_prompt = ["greeting#{random_greeting.join("")}.wav"]
        elsif session[student_id]["intent"] == "risk_to_depression"
            kw_prompt = survey_first_question(session, student_id)
            # kw_prompt << survey_prompt
            kw_prompt.flatten!
        elsif session[student_id]["intent"].blank?
            kw_prompt = ["retry1.wav"]
        else
            kw_prompt = case session[student_id]["intent"]
                when "education_problem" then group_education_prompt(session[student_id], "confirm")
                when "family_problem" then group_family_prompt(session[student_id], "confirm")
                when "money_problem" then group_money_prompt(session[student_id], "confirm")
                when "communication_problem" then group_communication_prompt(session[student_id], "confirm")
                when "love_problem" then group_love_prompt(session[student_id], "confirm")
                else ["retry1.wav"]
            end
            session["state"] = "confirm"
        end
        return kw_prompt
    end

    def confirm_dialog session, student_id, intent
        if intent =~ /yes/i || (session[student_id]["intent"] == intent)
            kw_prompt = case session[student_id]["intent"]
                when "education_problem" then group_education_prompt(session[student_id])
                when "family_problem" then group_family_prompt(session[student_id])
                when "money_problem" then group_money_prompt(session[student_id])
                when "communication_problem" then group_communication_prompt(session[student_id])
                when "love_problem" then group_love_prompt(session[student_id])
            else ["retry1.wav"]
            end
            
            if session[student_id].dig("keyword", "depression_symptoms").present?
                survey_prompt = survey_first_question(session, student_id)
                kw_prompt << survey_prompt
                kw_prompt.flatten!
            else
                kw_prompt << "more_question.wav" if kw_prompt.present? && !kw_prompt.include?("retry1.wav")
                session["state"] = "main"
            end
        elsif intent =~ /no/i
            kw_prompt = ["ask_intent_again.wav"]
            session["state"] = "main"
        else
            kw_prompt = ["retry_confirm.wav"]
        end

        return kw_prompt
    end

    def get_depression_key store_intent
        keywords = []
        store_intent["store_survey"] ||= {}
        store_intent["keyword"]["depression_symptoms"].each do |k|
            key = case k
                when "เบื่อ", "เครียด", "หงุดหงิด", "ไม่สนุก" then 1
                when "รู้สึกแย่", "ท้อ", "ไม่มีความสุข", "เศร้า" then 2
                when "พักผ่อนไม่เพียงพอ" then 3
                when "เหนื่อย" then 4 
                when "เบื่ออาหาร", "กินเยอะเกินไป" then 5
                when "ไร้ค่า", "ผิดหวัง", "ล้มเหลว" then 6
                when "สมาธิสั้น", "ความจำสั้น" then 7
                when "กระวนกระวาย" then 8
                when "ฆ่าตัวตาย", "ทำร้ายตัวเอง", "ตาย" then 9
                else k
                end
            keywords << key
            store_intent["store_survey"]["#{key.to_s}"] = "yes"
        end
        keywords
    end

    def get_default_prompt intent
        prompts = []
        prompts << "#{intent}/default.wav"
        prompts
    end

    def group_education_prompt store_intent, type=nil
        kw_education = store_intent["keyword"]["education"]
        prompts = []
        kw_education.each do |kw|
            # next if kw == "การเรียน"
            keys = case kw
                    when "เรียนไม่รู้เรื่อง", "สอน", "อ่านหนังสือ" then "study" #### ไม่ค่อยดีเท่าไหร่
                    when "เกรด", "สอบ", "คะแนน" then "grade"
                    when "ศึกษาต่อ", "มหาลัย", "มหาวิทยาลัย" then "university"
                    when "การบ้าน" then "work"
                    when "ติดศูนย์", "ติด ร", "หมดสิทธิ์สอบ" then "0"
                    when "กิจกรรม" then "event"
                    when "สอบตก" then "exam_fail"
                    end

            keys = "university" if store_intent["keyword"]["major"].present?

            if keys.present?
                if type.present?
                    prompts << "#{store_intent["intent"]}/#{type}_#{keys}.wav"
                else
                    if keys == "university"
                        keys = store_intent["keyword"]["major"].present? ? "#{keys}_future" : "#{keys}_exam"
                    end
                    prompts << "#{store_intent["intent"]}/#{keys}.wav"
                end
            end
            break if prompts.present?
        end

        prompts
    end

    def group_family_prompt store_intent, type=nil
        prompts = []
        store_intent["keyword"].each_with_index do |(key, val), index|
            next unless key == "abandonment" || key == "violence"
            keys = key if key == "abandonment" && val.present?
            if key == "violence" && val.present?
                keys = case val.first
                        when "เปรียบเทียบ", "รังแก", "bully", "นินทา" then "violence_bully"
                        else "violence"
                        end
            end

            if keys.present?
                prompts = type.present? ? ["#{store_intent["intent"]}/#{type}_#{keys}.wav"] : ["#{store_intent["intent"]}/#{keys}.wav"]
            end

            break if prompts.present?
        end
        prompts
    end

    def group_money_prompt store_intent, type=nil
        kw_money = store_intent["keyword"]["money"]
        prompts = []
        kw_money.each do |kw|
            keys = case kw
                    when "ทุนการศึกษา" then "scholarship"
                    when "เงินเก็บ", "รายรับ" then "deposit"
                    when "รายจ่าย" then "expenses"
                    end
            
            if keys.present?
                prompts = type.present? ? ["#{store_intent["intent"]}/#{type}_#{keys}.wav"] : ["#{store_intent["intent"]}/#{keys}.wav"]
            end
            break if prompts.present?
        end
        prompts
    end

    def group_communication_prompt store_intent, type=nil
        prompts = []
        kw_people = store_intent["keyword"]["people"]
        someone = case kw_people.first
                    when "เพื่อน" then "friend"
                    when "ครู" then "teacher"
                    end 

        store_intent["keyword"].each_with_index do |(key, val), index|
            next unless key == "abandonment" || key == "violence" || key == "education" || key == "drug"
            keys == "education" if key == "education" && val.present?
                
            

            keys = "abandonment" if key == "abandonment" && val.present?
                
            if key == "violence" && val.present?
                violence_kw = case val
                            when "เปรียบเทียบ", "รังแก", "bully", "นินทา" then "violence_bully"
                            else "violence"
                            end
                keys = someone.present? ? "#{someone}_#{violence_kw}" : violence
            end

            keys = "drug" if key == "drug" && val.present?
            
            if keys.present?
                prompts = type.present? ? ["#{store_intent["intent"]}/#{type}_#{keys}.wav"] : ["#{store_intent["intent"]}/#{keys}.wav"]
            end

            break if prompts.present?
        end
        prompts
    end

    def group_love_prompt store_intent, type=nil
        prompts = []
        store_intent["keyword"].each_with_index do |(key, val), index|
            next unless key =~ /love/i || key == "violence" || key == "gender"
        
            if key == "love_feeling" && val.present?
                keys = case val.first
                        when "รัก", "ชอบ", "สนใจ" then "love"
                        when "เลิก", "นอกใจ", "ไม่สนใจ" then "unlove"
                        when "เพศสัมพันธ์" then "sex"
                        end
            elsif val.present?
                keys = key
            end

            if keys.present?
                prompts = type.present? ? ["#{store_intent["intent"]}/#{type}_#{keys}.wav"] : ["#{store_intent["intent"]}/#{keys}.wav"]
            end

            break if prompts.present?
        end
        prompts
    end

    def survey_first_question session, student_id
        prompts = []
        session["state"] = "survey"
        session["survey_count"] = 0
        prompts << "depression_survey/survey_0.wav"
        arr_depression_survey = (1..2).to_a.map(&:to_s)
        get_keyword = get_depression_key(session[student_id])
        arr_depression_survey -= get_keyword
        rand_survey = arr_depression_survey.sample(1)
        prompts << "depression_survey/survey_#{rand_survey.join()}.wav"
        session[student_id]["store_survey"]["#{rand_survey.join()}"] = nil
        prompts
    end

    def survey_random_question session, student_id, intention
        arr_depression_survey = (1..2).to_a.map(&:to_s)
        prompts = []

        ### แก้ไขให้ตอบเป็นคะแนน ####
        answer = intention =~ /yes/i || (session[student_id]["intent"] == intention) ? "yes" : "no"
        ##########################

        keys_of_survey = session[student_id]["store_survey"].keys
        # session[student_id]["store_survey"].map{ |k,v| k = answer if v.blank? }
        session[student_id]["store_survey"][keys_of_survey[-1]] = answer
        get_keyword = session[student_id]["store_survey"]
        arr_depression_survey -= keys_of_survey

        if arr_depression_survey.blank?
            prompts << "thank_you.wav"
            prompts << "more_question.wav"
            session["state"] = "main"
            send_depression_survey(session, student_id)
        else
            rand_survey = arr_depression_survey.sample(1)
            prompts << "depression_survey/survey_#{rand_survey.join()}.wav"
            session[student_id]["store_survey"]["#{rand_survey.join()}"] = nil
        end
        prompts
    end

    def send_depression_survey session, student_id
        user = session["current_user"]
        teacher = User.where(classroom: user["classroom"], role: 1)
        question = read_json("./lib/prompt_text.json")
        question = question.reject{ |k, v| !(k =~ /depression_survey/i) }
        teacher.each do |t|
            NotificationDepressionMailer.send_notification(t, user, question, session[student_id]["store_survey"]).deliver_now
        end
        # redirect_to root_path()
    end

    def get_prompt_script prompts
        all_script = read_json("./lib/prompt_text.json")
        script = []
        prompts.each do |pr|
            script << all_script[pr] 
        end
        return script.join(" ")
    end

    def read_json file
        return data = JSON.parse(open(file).read)
    end

end
