class TestAuthController < ApplicationController
  def index
    if RAILS_ENV != 'development'
      redirect_to :controller => 'opportunity_list'
      return
    end
    @user = request.env['REMOTE_USER']
    # redirect_to :controller => ''
    # ENV["REMOTE_USER"] = 'wlbland'
  end
  
  def echo
    if RAILS_ENV != 'development'
      redirect_to :controller => 'opportunity_list'
      return
    end
    @remote_user = request.env['REMOTE_USER']
    @session_id = session[:netid]
    @netid = userNetID
  end
  
  def set
    if RAILS_ENV == 'production'
      redirect_to :controller => 'opportunity_list'
      return
    end
    session[:netid] = params[:username]
    redirect_to :controller => ''
  end
  
  def rick_is_student
    rick = User.find_by_netID('fewayne')
    rick.isInstructor = 0
    rick.save!
    flash[:notice] = 'Rick is now a mere mortal'
    redirect_to "/"
  end

  def rick_is_instructor
    rick = User.find_by_netID('fewayne')
    rick.isInstructor = 1
    rick.save!
    flash[:notice] = 'Rick is again among the godly ranks'
    redirect_to "/"
  end
end
