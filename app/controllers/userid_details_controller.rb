class UseridDetailsController < ApplicationController
 require 'userid_role'

skip_before_filter :require_login, only: [:general, :create,:researcher_registration, :transcriber_registration,:technical_registration]
rescue_from ActiveRecord::RecordInvalid, :with => :record_validation_errors

	def index
    get_user_info(session[:userid],session[:first_name])
    session[:type] = "manager"
    session[:my_own] = "no"
    @role = session[:role]
    @userids = UseridDetail.get_userids_for_display(session[:syndicate],params[:page]) 
  end #end method

 

  def new
    session[:type] = "add"
    @userid = UseridDetail.new
    get_user_info(session[:userid],session[:first_name])
    @role = session[:role]
    @syndicates = Syndicate.get_syndicates_open_for_transcription   
  end
   
  def show
    load(params[:id])

  end

  def all
   get_user_info(session[:userid],session[:first_name])
   @userids = UseridDetail.get_userids_for_display('all',params[:page]) 
   render "index"
  end


  def my_own
    session[:my_own] = 'my_own'
    get_user_info(session[:userid],session[:first_name])
    @userid = @user
    render :action => 'show'

  end

  def edit
    session[:type] = "edit"
    load(params[:id])
    @syndicates = Syndicate.get_syndicates


  end
 

  def change_password
    load(params[:id])
    @userid.send_invitation_to_reset_password
    flash[:notice] = 'An email with instructions to reset the password have been sent'
     render :action => 'show'
    
  end

  def general
   session[:first_name] = 'New Registrant'
  end

  def researcher_registration
   session[:first_name] = 'New Registrant'
   session[:type] = "researcher_registration"
   @userid = UseridDetail.new
   @first_name = session[:first_name]
  end 

  def transcriber_registration
   session[:first_name] = 'New Registrant'
   session[:type] = "transcriber_registration"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
    @syndicates = Syndicate.get_syndicates_open_for_transcription
  end 

  def technical_registration
   session[:first_name] = 'New Registrant'
   session[:type] = "technical_registration"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
  end 

  

  def create
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first unless session[:userid].nil?
     @userid = UseridDetail.new(params[:userid_detail])
     @userid.add_fields(params[:commit])
     @userid.save
   
     if @userid.errors.any?
        flash[:notice] = 'The registration was unsuccessful'
          @syndicates = Syndicate.get_syndicates_open_for_transcription
        next_place_to_go_unsuccessful
     else
       flash[:notice] = 'The addition of the person was successful'
       next_place_to_go_successful(@userid)
     end
  end

  def update
    load(params[:id])
  	if session[:type] == "disable" 
  	 params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil? 
     params[:userid_detail][:active]  = false  
    end
    params[:userid_detail][:person_role] = params[:userid_detail][:person_role] unless params[:userid_detail][:person_role].nil?
    @userid.update_attributes!(params[:userid_detail])
    
   if @userid.errors.any?
        flash[:notice] = 'The registration was unsuccessful'
          @syndicates = Syndicate.get_syndicates_open_for_transcription
        next_place_to_go_unsuccessful
     else
       flash[:notice] = 'The addition of the person was successful'
       next_place_to_go_successful(@userid)
     end
end

def destroy
   
   load(params[:id])
   @userid.destroy
   flash[:notice] = 'The destruction of the userid was successful'
    redirect_to :action => 'all'
end

 def disable
  load(params[:id])
 	session[:type] = "disable"
 end

  def load(userid_id)
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.find(userid_id)
    session[:userid_id] = userid_id
    @role = session[:role]
  end

def next_place_to_go_unsuccessful
   case 
         when session[:type] == "add"
          render :action => 'new' 
          return
         when session[:type] == 'researcher_registration'
          render :action => 'researcher_registration'
          return
         when session[:type] == 'transcriber_registration'
            render :action => 'transcriber_registration'
          return
         when session[:type] == 'technical_registration'
            render :action => 'technical_registration'
            return
         else
          render :action => 'new' 
          return
    end
end

  def next_place_to_go_successful(userid)
     @userid.finish_creation_setup if params[:commit] == 'Submit'
     @userid.finish_researcher_creation_setup if params[:commit] == 'Register Researcher'
     @userid.finish_transcriber_creation_setup if params[:commit] == 'Register Transcriber'
     @userid.finish_technical_creation_setup if params[:commit] == 'Technical Registration'
   case 
         when session[:type] == "add"
          
           if @user.person_role == 'system_administrator'
              redirect_to :action => 'all'
              return
           else
              redirect_to userid_details_path(:anchor => "#{ @userid.id}")
              return
           end
          when session[:type] == 'researcher_registration' || session[:type] == 'transcriber_registration' || session[:type] == 'technical_registration'
            redirect_to refinery.logout_path
            return
          else
            redirect_to refinery.login_path
          return
    end
    redirect_to refinery.login_path
end

def record_validation_errors(exception)
  flash[:notice] = "The registration was unsuccessful due to #{exception.record.errors.messages}"
  @userid.delete
  next_place_to_go_unsuccessful
end

end

