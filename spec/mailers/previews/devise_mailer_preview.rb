# Preview all emails at http://localhost:3000/rails/mailers/devise/mailer
class DeviseMailerPreview < ActionMailer::Preview

  # Accessible from http://localhost:3000/rails/mailers/devise/mailer/confirmation_instructions
  def confirmation_instructions
    user = User.last
    token = user.confirmation_token || "some_temporary_token"
    Devise::Mailer.confirmation_instructions(user, token)
  end
end
