class MessagesController < ApplicationController
  require 'freereg_options_constants'
  require 'userid_role'
  def index
    get_user_info_from_userid
    @messages = Message.all.order_by(message_time: -1)
  end

  def show
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    @message_sent = @message.sent_messages.where(message_id: @message.id,sender: @user.userid,checked: false)
    @message_sent.to_a[0].update_attribute(:checked,true) if @message_sent.to_a.length == 1
    if @message.blank?
      go_back("message",params[:id])
    end
    @sent =   @message.sent_messages.order_by(sent_time: 1)
  end

  def list_by_name
    get_user_info_from_userid
    @messages = Message.all.order_by(userid: 1)
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @messages = Message.all.order_by(identifier: -1)
    render :index
  end


  def list_by_date
    get_user_info_from_userid
    @messages = Message.all.order_by(message_time: 1)
    render :index
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    @messages = Message.all.order_by(identifier: -1).each do |message|
      @options[message.identifier] = message.id
    end
    @message = Message.new
    @location = 'location.href= "/messages/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def new
    get_user_info_from_userid
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid

  end

  def create
    @message = Message.new(message_params)
    @message.file_name = @message.attachment_identifier
    if @message.save
      flash[:notice] = "Message created"
      redirect_to :action => 'index'
      return
    else
      redirect_to  :new
      return
    end
  end

  def send_message
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    if @message.present?
      @options = UseridRole::VALUES
      @sent_message = SentMessage.new(:message_id => @message.id, :sent_time => Time.now,:sender => @userid)
      @message.sent_messages <<  [ @sent_message ]
      @sent_message.save
      @sent_message.active = true
      @message.action =  @sent_message.id
      @inactive_reasons = Array.new
      UseridRole::REASONS_FOR_INACTIVATING.each_pair do |key,value|
        @inactive_reasons << value
      end
      @senders = Array.new
      @senders << ''
      UseridDetail.active(true).all.order_by(userid_lower_case: 1).each do |sender|
        @senders << sender.userid
      end
    else
      go_back("message",params[:id])
    end

  end

  def edit
    @message = Message.id(params[:id]).first
    if @message.blank?
      go_back("message",params[:id])
    end
  end

  def update

    @message = Message.id(params[:id]).first
    if @message.present?
      case params[:commit]
      when "Submit"
        @message.update_attributes(message_params)
      when "Send"
        sender = params[:sender]
        @sent_message = @message.sent_messages.id(params[:message][:action]).first
        active = false
        active = true if params[:active] == "true"
        reasons = Array.new

        @message_userid =  UseridDetail.find_by(userid: @message.userid).userid_messages
        @message_userid << @message
        UseridDetail.find_by(userid: params[:sender]).update_attribute(:userid_messages, @message_userid)

        params[:inactive_reasons].blank?  ? reasons << 'temporary' : reasons =  params[:inactive_reasons]
        @sent_message.update_attributes(:recipients => params[:recipients], :active => active, :inactive_reason => reasons, :sender => sender)
        @message.communicate(params[:recipients],  active, reasons,sender)
        flash[:notice] = "Message sent to Recipients: #{params[:recipients]}; Active : #{active} #{reasons}" if !active
        flash[:notice] = "Message sent to Recipients: #{params[:recipients]}; Active : #{active} " if active

      end
      redirect_to :action => 'show'
      return
    else
      go_back("message",params[:id])
    end
  end

  def destroy
    @message = Message.id(params[:id]).first
    if @message.present?
      @message.destroy
      flash.notice = "Message destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("message",params[:id])
    end
  end
  private
  def message_params
    params.require(:message).permit!
  end

end
