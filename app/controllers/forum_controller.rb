class ForumController < ApplicationController
    def index
        @question = Question.new
        @tag = Tag.all
    end

    def datatables
        respond_to do |format|
            format.html
            format.json { render json: ForumDatatable.new(params, view_context: view_context) }
        end
    end

    def create_question
        form_data = params[:question]
        json_character = JSON.parse(generate_fake_characters.to_json)
        tag_id = form_data[:tag_id].reject { |t| t.empty? }
        if tag_id.present?
            tag_id.map!(&:to_i)
        end

        @question = Question.create(question: form_data[:question], user_id: session["current_user"]["id"], fake_characters: json_character, status: 1, tag_id: tag_id.join(','))
        if @question
            flash[:success] = "Your question are posted successfully!"
            redirect_to forum_path()
        else
            flash[:error] = "Error: Cannot post your question. Please try again"
            redirect_to forum_path(question: params[:question])
        end
    end

    def show_comment
        @comment = Comment.new
        @question_data = Question.find(params[:question])
        @fake_char = @question_data["fake_characters"]
        tag = Tag.all
        @tag = tag.index_by(&:id)
    end

    def comment_datatable
        respond_to do |format|
            format.html
            format.json { render json: ShowCommentDatatable.new(params) }
        end
    end

    def create_comment
        form_data = params[:comment]
        json_character = JSON.parse(generate_fake_characters(params["own_char"]).to_json)

        @comment = Comment.create(comment: form_data[:comment], user_id: session["current_user"]["id"], question_id: params[:question_id], fake_characters: json_character, status: 1)
        if @comment
            flash[:success] = "Your comment are posted successfully!"
            redirect_to forum_path()
        else
            flash[:error] = "Error: Cannot comment the question. Please try again"
            redirect_to forum_path(question: params[:question])
        end
    end

    private
    def post_params
        params.require(:question).permit(:question, :user_id, :fake_characters, :status)
    end

    def generate_fake_characters own_char={}
        h_character = Hash.new

        friut = ["apple", "strawberry", "orange", "banana", "water_melon", "lemon", "kiwi"]
        number = (0..255).to_a

        if own_char.present?
            own_user_pic = own_char["user"]
            own_color = own_char["color"]
            i = 1
            while i > 0 do
                comment_user_pic = friut.sample(1).join()
                comment_color = number.sample(3).join(" ")
                unless comment_user_pic == own_user_pic && comment_color == own_color
                    i = 0
                    h_character[:user] = comment_user_pic
                    h_character[:color] = comment_color
                end
            end
        else
            h_character[:user] = friut.sample(1).join()
            h_character[:color] = number.sample(3).join(" ")
        end
        h_character
    end
end
