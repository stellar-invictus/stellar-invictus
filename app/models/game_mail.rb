class GameMail < ApplicationRecord
  paginates_per 10
  
  belongs_to :sender, :foreign_key => "sender_id", :class_name => "User"
  belongs_to :recipient, :foreign_key => "recipient_id", :class_name => "User"
  
  validates :body, presence: true
  validates :header, presence: true
  
  validates :body, length: { maximum: 500, too_long: I18n.t('validations.too_long_mail_body') }
  validates :header, length: { maximum: 100, too_long: I18n.t('validations.too_long_mail_header') }
  
  after_create do
    if units and units > 0 and units <= sender.units
      sender.reduce_units(units)
      recipient.give_units(units)
    end
  end
  
  after_create_commit {GameMailWorker.perform_async(self.recipient.id)}
end
