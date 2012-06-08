class LabSessionsController < ApplicationController
  
  before_filter :instructors_only, :only => [:new, :create, :edit, :update, :destroy]
  
  def instructors_only
    @cur_user = curUser
    unless curUser.isInstructor
      flash[:notice] = 'Unauthorized'
      redirect_to :action => :list
    end
  end
  
  def index
    @cur_user = curUser
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @cur_user = curUser
    @lab_sessions = LabSession.for_user(curUser)
  end

  def show
    @cur_user = curUser
    @lab_session = LabSession.find(params[:id])
    @lab_session.datetime = @lab_session.to_local
  end

  def new
    @lab_session = LabSession.new :duration => 55, :lab_location => LabLocation.default
    @lab_opportunities,@lab_session.lab_opportunity = LabOpportunity.current_or_soon
    unless @lab_session.lab_opportunity
      @lab_session.lab_opportunity = @lab_opportunities.first
    end
  end

  def create
    @lab_session = LabSession.new(params[:lab_session])
    logger.info "datetime is #{@lab_session.datetime}"
    @lab_session.local_to_gmt! if @lab_session.datetime
    if @lab_session.save
      flash[:notice] = 'LabSession was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @lab_session = LabSession.find(params[:id])
    @lab_session.datetime = @lab_session.to_local
    @lab_opportunities,@soon_opp = LabOpportunity.current_or_soon
  end

  def update
    @lab_session = LabSession.find(params[:id])
    if @lab_session.update_attributes(params[:lab_session])
      @lab_session.local_to_gmt!
      @lab_session.save # Saving twice to get around UTC stuff
      flash[:notice] = 'LabSession was successfully updated.'
      redirect_to :action => 'show', :id => @lab_session
    else
      render :action => 'edit'
    end
  end

  def destroy
    LabSession.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def signup_params
    @lab_session = LabSession.find(params[:id])
    @student = User.find(params[:student])
    @cur_user = curUser
    unless @cur_user.isInstructor || @cur_user.id == @student.id
      flash[:notice] = 'Operation not allowed.'
      logger.info 'lab_session signup params -- unauthorized op'
      redirect_to :controller => 'lab_sessions', :action => 'list'
      return false
    end
    true
  end

  def signup_student
    unless signup_params && !@lab_session.closed
      log_mesg = 'lab_session signup failed: '
      if @lab_session == nil
        log_mesg += 'Lab session object was nil'
      elsif @lab_session.closed
        log_mesg += "lab session closed, #{@lab_session.inspect} "
        # log_mesg += @lab_session.closed_why
      else
        log_mesg += "bad params: #{params.inspect}"
      end
      logger.warn log_mesg
      redirect_to :action => 'list'
      return
    end
    if (signup = @lab_session.existing_signup_in_opp(@student))
      logger.info "student #{@student.full_name} signed up already, tried again"
      flash[:notice] = "#{@student.full_name} already registered for #{signup.lab_session.show_date}"
      redirect_to :action => 'list'
      return
      end
    signup = LabSignup.new :lab_session => @lab_session, :user => @student
    @lab_session.lab_signups << signup
    unless @lab_session.save
      flash[:notice] = 'Signup could not be processed.'
      logger.warn "lab_session signup could not be saved after signup added: \n\t#{@lab_session.errors.inspect}\n\t#{@lab_session.inspect}, \n\t#{@student.inspect}, \n\t#{signup.inspect}"
      redirect_to :action => 'list'
      return
    end
    flash[:notice] = 
      "#{@student.full_name} is signed up for the lab at #{@lab_session.lab_location.name}, #{@lab_session.show_date}"
    redirect_to :action => 'list'
  end

  def cancel_student
    return unless signup_params
    signup = @lab_session.existing_student_signup(@student)
    unless signup
      flash[:notice] = 'Signup not found.'
      redirect_to :action => 'list'
      return
    end
    @lab_session.lab_signups.delete(signup)
    LabSignup.destroy(signup)
    unless @lab_session.save
      flash[:notice] = 'Signup could not be deleted.'
      redirect_to :action => 'list'
      return
    end
    flash[:notice] = 'Signup has been removed.'
    redirect_to :action => 'list'
  end
end
