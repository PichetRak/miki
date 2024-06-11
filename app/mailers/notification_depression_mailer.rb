class NotificationDepressionMailer < ApplicationMailer
    def send_notification(teacher, student, question, answer)
        @teacher = teacher
        @student = student
        @question = question
        @answer = answer
        mail(to: @teacher.email, subject: "แบบทดสอบภาวะซึมเศร้าของ #{student["firstname"]} #{student["lastname"]}")
    end
end
