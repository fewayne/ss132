class LabLocationsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @lab_location_pages, @lab_locations = paginate :lab_locations, :per_page => 10
  end

  def show
    @lab_location = LabLocation.find(params[:id])
  end

  def new
    @lab_location = LabLocation.new
  end

  def create
    @lab_location = LabLocation.new(params[:lab_location])
    if @lab_location.save
      flash[:notice] = 'LabLocation was successfully created.'
      if @from_session
        @from_session = false
        redirect_to :controller => 'lab_sessions', :action => 'new'
      else
        redirect_to :action => 'list'
      end
    else
      render :action => 'new'
    end
  end
  
  def create_within_session
    @from_session = true
    create
  end

  def edit
    @lab_location = LabLocation.find(params[:id])
  end

  def update
    @lab_location = LabLocation.find(params[:id])
    if @lab_location.update_attributes(params[:lab_location])
      flash[:notice] = 'LabLocation was successfully updated.'
      redirect_to :action => 'show', :id => @lab_location
    else
      render :action => 'edit'
    end
  end

  def destroy
    LabLocation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
