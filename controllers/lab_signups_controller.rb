class LabSignupsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @lab_signup_pages, @lab_signups = paginate :lab_signups, :per_page => 10
  end

  def show
    @lab_signup = LabSignup.find(params[:id])
  end

  def new
    @lab_signup = LabSignup.new
  end

  def create
    @lab_signup = LabSignup.new(params[:lab_signup])
    if @lab_signup.save
      flash[:notice] = 'LabSignup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @lab_signup = LabSignup.find(params[:id])
  end

  def update
    @lab_signup = LabSignup.find(params[:id])
    if @lab_signup.update_attributes(params[:lab_signup])
      flash[:notice] = 'LabSignup was successfully updated.'
      redirect_to :action => 'show', :id => @lab_signup
    else
      render :action => 'edit'
    end
  end

  def destroy
    LabSignup.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
