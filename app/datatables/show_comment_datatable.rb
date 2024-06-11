class ShowCommentDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      comment: { source: "Comment.comment", cond: :like },
      # name: { source: "User.name", cond: :like }
    }
  end

  def data
    records.map do |record|
      question = []
      character = record.fake_characters
      if character.present?
        red, green, blue = character["color"].split(" ")
        question << "<div class='div-user-pic' style='background: rgb(#{red}, #{green}, #{blue})'>
                    <img class='user-pic' height='60px' width='60px' src='/fake_user_pic/#{character["user"]}.png' />
                    </div>"
      end
      # count_comment = Comment.where(question_id: record.id).count
      content = []
      content << "<div class='div-question-data'>"
      content << "<span class='text-question'>#{record.comment}</span>"
      content << "</div>"
      question << content.join(" ")
      {
        comment: question.join("").html_safe
      }
    end
  end

  def get_raw_records
    # insert query here
    id = params[:id]
    query = Comment.where(question_id: id).order(updated_at: :DESC)
    query
  end

end
