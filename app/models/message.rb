class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  field :subject, type: String
  field :body, type: String
  field :message_time, type: DateTime
  field :userid, type: String
  field :attachment, type: String
  field :identifier, type: String
  field :path, type: String
  field :file_name, type: String
  field :images, type: String
  attr_accessor :action, :inactive_reasons,:active
  embeds_many :sent_messages
  accepts_nested_attributes_for :sent_messages,allow_destroy: true,
    reject_if: :all_blank

  mount_uploader :attachment, AttachmentUploader
  mount_uploader :images, ScreenshotUploader
  before_create :add_identifier

  class << self
    def id(id)
      where(:id => id)
    end
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def communicate(recipients,active,reasons,sender)
    sender_email = UseridDetail.userid(sender).first.email_address unless sender.blank?
    sender_email = "freereg-contacts@freereg.org.uk" if sender_email.blank?
    ccs = Array.new
    recipients.each do |recip|
      case
      when active
        UseridDetail.role(recip).active(active).email_address_valid.all.each do |person|
          ccs << person.email_address
        end
      when reasons.present? && !active
        reasons.each do |reason|
          UseridDetail.role(recip).active(active).reason(reason).email_address_valid.all.each do |person|
            ccs << person.email_address
          end
        end
      when reasons.blank? && !active
        easons.each do |reason|
          UseridDetail.role(recip).active(active).reason("temporary").email_address_valid.all.each do |person|
            ccs << person.email_address
          end
        end
      end
    end
    ccs = ccs.uniq
    UserMailer.send_message(self,ccs,sender_email).deliver_now
  end
end
