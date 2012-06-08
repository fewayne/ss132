class AdminUserController < ApplicationController
  before_filter :bump_em
  def index
    list
    render :action => 'list', :page => todays_page('News')
  end
  
  def no_names
    list
    @no_names = true
    render :action => 'list', :page => (params[:news_opportunity_id] || todays_page('News'))
  end
   
  def list
    @opportunity_pages, @opportunities = paginate :news_opportunity, :per_page => 1, :order => "phase_one_start DESC"
    @all_news_opps = Opportunity.find(:all,:conditions => ['type = "NewsOpportunity"'], :order => "phase_one_start DESC")
  end

  def collect_their_work
    @user = User.find(:first, :conditions => ['id = ?',params[:id]])
    @opportunity = NewsOpportunity.find(params[:news_opportunity_id])
    if @opportunity != nil
      @item = @opportunity.items_from(@user.id).first
      @questions = @opportunity.questions_from(@user.id)
      @responses = @opportunity.responses_from(@user.id)
    end
  end
  
  protected :collect_their_work
  
  def show
    collect_their_work
  end

  def new
    redirect_to :controller => 'opportunity_list'  
#    @user = User.new
  end

  def create
    redirect_to :controller => 'opportunity_list'  
#    @user = User.new(params[:user])
#    if @user.save
#      flash[:notice] = 'User was successfully created.'
#      redirect_to :action => 'list'
#    else
#      render :action => 'new'
#    end
  end

  def edit
    collect_their_work
  end

  def update
    redirect_to :controller => 'opportunity_list'  
#    @user = User.find(params[:id])
#    if @user.update_attributes(params[:user])
#      flash[:notice] = 'User was successfully updated.'
#      redirect_to :action => 'show', :id => @user
#    else
#      render :action => 'edit'
#    end
  end

  def destroy
    # Append all their points, items, questions, responses, and their user record onto the "deleted" tables/text file
    # Note that their presence in "deleted" makes their login bounce (ApplicationController.curUser)
    # If we're in the middle of an ITN opp && this user has posted an item && others have posted a question to it
    #   Delay until the end of ITN
    # Else
    #   Delete all their points, items, questions, responses, and their user record
    #
#    User.find(params[:id]).destroy
#    redirect_to :action => 'list'
    redirect_to :controller => 'opportunity_list'  
  end
  
  # def AdminUserController.userNetId
  # 	request.env['REMOTE_USER'] || 'unknown'
  # end

  def assign_points
    points_str = request.raw_post || request.query_string
    fields = points_str.split(/_/)
    return @results = "ERROR: Malformed input" if fields.size != 2
    point_value = fields[0]
    point_rec_id = fields[1]
    points = Point.find(point_rec_id)
    return @results = "ERROR: No student points record" if points == nil
    points.final_points = point_value
    begin
      points.save!
    rescue
      return @results = "ERROR: Couldn't save student points record"
    end
    @results = "OK"
  end
  
  def clobber
    @news_opportunity_id = params[:news_opportunity_id]
    # Note that the param here means "user id to clobber", not "user id doing the clobbering"
    @user_id = params[:user_id]
    return @clobber_results = "ERROR: Missing params" if @news_opportunity_id == nil || @user_id == nil
    points = Point.find(:first, :conditions => ["news_opportunity_id = #{@news_opportunity_id} and user_id = #{@user_id}"])
    return @clobber_results = "ERROR: No student points record" if points == nil
    
    points.clobbered = 1
    begin
      points.save!
    rescue
      return @clobber_results = "ERROR: Could not save student points record"
    end
    # Semantics have changed: Now, no news is good news
    @clobber_results=""
  end
  
  def activity_summary
    begin
      user = User.find(params[:uid])
      render_text "Placeholder for a summary page: will list all activity for user #{user.netID}"
    rescue
      render_text "User not specified or not found"
    end
  end
  
end
