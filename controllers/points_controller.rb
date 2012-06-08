class PointsController < ApplicationController
  before_filter :bump_em
  def index
    list
    render :action => 'list'
  end

  def list
    @point_pages, @points = paginate :points, :per_page => 10
  end

  def show
    @point = Point.find(params[:id])
  end

  def new
    @point = Point.new
  end

  def create
    if (set_context)
      @point = Point.new(params[:point])
      if @point.save
        flash[:notice] = 'Point record for #{@user.full_name} was successfully created.'
        redirect_to :action => 'list'
      else
        render :action => 'new'
      end
    end
  end
  
  def set_context
    @item = Item.find(params[:item_id]) unless params[:item_id] == nil
    @opportunity = @item.news_opportunity unless @item == nil
    @user = @item.user unless @item == nil
    if @item == nil || @opportunity == nil || @user == nil
      mesg = 'Application error: '
      mesg += "Item was nil, id was #{Item.quote_value(params[:item])}" if @item == nil
      mesg += ' Opp was nil' if @opportunity == nil
      mesg += ' User was nil' if @user == nil
      flash[:notice] = mesg
      redirect_to :controller => 'admin_user'
      return false
    end
    @point = Point.find(:first,:conditions => ["opportunity_id = ? and user_id = ?",@opportunity.id,@user.id])
    @questions = @opportunity.questions_from(@user.id)
    true
  end
  
  protected :set_context
  
  def edit
    if (set_context)
      if (@point == nil)
        @point = Point.new
      end
    end
  end

  def success
    flash[:notice] = "Point was successfully created and saved."
    opp = @point.opportunity
    redirect_to :controller => 'admin_user', :page => pagenum_for(opp,NewsOpportunity.find(:all))
  end
  
    
  def update
    if (params[:id] == nil || (@point = Point.find(params[:id])) == nil)
      @point = Point.new(params[:point])
      if @point.save
        success
      else
        flash[:notice] = 'Database error, grade could not be saved, contact Rick'
        render :action => 'edit'
      end
    elsif @point.update_attributes(params[:point])
      success
    else
      render :action => 'edit'
    end
  end

  def destroy
    Point.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
