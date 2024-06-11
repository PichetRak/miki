class ForumDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable
  def_delegators :@view, :link_to, :forum_questions_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      question: { source: "Question.question", cond: :like },
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
      time_now = Time.parse(DateTime.now().strftime("%Y-%m-%d %H:%M:%S"))
      updated_date = Time.parse("#{record.updated_at.strftime("%Y-%m-%d %H:%M:%S")} +0700")
      diff_time = time_now - updated_date
      if diff_time >= 86400
        time_text = record.updated_at.strftime("%d/%m/%Y")
      elsif diff_time >= 3600 && diff_time < 86400
        time_text = "#{(diff_time / 3600).to_i} hours ago"
      elsif diff_time >= 60 && diff_time < 3600
        time_text = "#{(diff_time / 60).to_i} minutes ago"
      else
        time_text = "a few minute ago"
      end
      count_comment = Comment.where(question_id: record.id).count
      content = []
      content << "<div class='div-question-data'>"
      content << link_to(record.question.html_safe, forum_questions_path(question: record.id), class: "text-question link-question")
      content << "<span class='updated-time-forum'>#{time_text}</span>"
      if record.tag_id.present?
        tags = record.tag_id.split(',')
        content << "<div class='div-tag'>"
        tags.each{ |t, i| content << "<span class='badge text-bg-tag tag-#{t.to_i}'>#{@tag[t.to_i].tag_th}</span>"}
        content << "</div>"
      end
      content << "<div class='div-count-comment'>"
      content << link_to("#{count_comment} comment(s)".html_safe, forum_questions_path(question: record.id), class: "count-comment link-question")
      content << "</div>"
      content << "</div>"
      question << content.join(" ")

      {
        question: question.join("").html_safe
      }
    end
  end

  def get_raw_records
    # insert query here
    query = Question.where.not(status: 2)
    
    params["tag"].each {|t| query = query.where("tag_id like ?", "%#{t}%")} if params["tag"].present? && !params["tag"].include?("0")
    
    tags = Tag.all
    @tag = tags.index_by(&:id)
    query = query.order(updated_at: :DESC)
    # query.sort_by(updated_at: :DESC)
    query
  end

end
