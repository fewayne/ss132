class AdminItemController < ApplicationController
  before_filter :bump_em, :only => [:destroy]
  before_filter :log_user

  def home
    @curUser = curUser
  end
  
  def index
    list
    render :action => 'list'
  end

  def list
    @item_pages, @items = paginate :item, :per_page => 10
  end

  def show
    @item = Item.find(params[:id])
  end

  def check_already(opportunity_id,user_id)
    items_already = Item.find_by_user_id_and_news_opportunity_id(user_id,opportunity_id)
    if (items_already != nil)
      flash[:notice] = "You have already entered an item for this learning opportunity"
      redirect_to :controller => 'opportunity_list'
      return true
    end
    return false
  end
  
  def new
    @item = Item.new
    @item.user_id = get_user_id
    @item.news_opportunity_id = params[:news_opportunity_id]
    if (@item.news_opportunity_id == nil)
        flash[:notice] = "nil opp id!"
        redirect_to :controller => 'admin_item'
        # opportunity_id = Opportunity.open_for_items
    end
    check_already(@item.news_opportunity_id,@item.user_id)
  end

  def create
    # if the caller didn't pass an opp in to us, use the first one open for item posting
    begin
      opportunity_id = params[:news_opportunity_id]
      if (opportunity_id == nil)
         opportunity_id = NewsOpportunity.open_for_items
      end
      @item = Item.new(params[:item])
      @item.news_opportunity_id = opportunity_id
      @item.posted = Time.now
      @item.user_id = get_user_id
      if check_already(opportunity_id,@item.user_id)
        logger.info('user already has an item in this opportunity')
        return
      end
      
      if @item.save
        # so long as there is one item per student per oppo, item creation time is an
        # auspiscious moment to create their points record too
        @student_points = Point.find_by_user_id_and_opportunity_id(opportunity_id,@item.user_id)
        @student_points = Point.new if @student_points == nil
        @student_points.opportunity_id = opportunity_id
        @student_points.user_id = @item.user_id
        @student_points.final_points = '0'
        if !@student_points.save
          flash[:notice] = "Could not create point record! Please contact your instructor."
          logger.warn(flash[:notice])
          render :action => 'new'
        else
          flash[:notice] = "Item recorded; assigned id #{@item.id}. You will need this ID to access your item next week, so please make a note of it!"
          # delay one second to hopefully thwart weird double-item-creation bug
          sleep 1
          # this was just to action "list" here
          redirect_to :controller => 'opportunity_list', :action => 'news_show', :id => opportunity_id
        end
      else
        flash[:notice] = "Could not save item!"
        logger.warn(flash[:notice])
        logger.warn @item.inspect
        render :action => 'new'
      end
    rescue Exception => ex # null oppo?
      flash[:notice] = 'No opportunities are currently open for adding items, or you are not logged in as a registered user ' + ex.to_s
      logger.warn ex.to_s
      logger.warn ex.backtrace
      redirect_to :controller => 'opportunity_list', :action => 'list'
    end
  end

  def edit
   # # @item = Item.find(params[:id])
   # unless (opportunity_id = params[:news_opportunity_id]) && (@item = Item.new(params[:item]))
   #   redirect_to :controller => 'opportunity_list', :action => 'news_show'
   # end
   # render :action => 'new'
  end

  def update
    @item = Item.find(params[:id])
    unless @item  && @item.user_id == curUser[:id]
      redirect_to :controller => 'opportunity_list'
      return
    end
    params[:item] = {:description => params[:item][:description]}
    if @item.update_attributes(params[:item])
     flash[:notice] = 'Item was successfully updated.'
     redirect_to :action => 'show', :id => @item
    else
     render :action => 'edit'
    end
  end

  def destroy
    item = Item.find(params[:id])
    if item.questions.size > 0
      flash[:notice] = 'Item has questions posted. Cannot delete.'
    else
      qs_to_delete = item.news_opportunity.questions_from(item.user.id)
      if item
       point = Point.find(:first,
        :conditions => ['user_id = ? and opportunity_id = ?',item.user_id,item.news_opportunity_id])
        if point
          point.destroy
          item.destroy
          if qs_to_delete
            qs_to_delete.each {|q| q.destroy unless q.q_response}
          end
        else
          logger.warn "Attempt to destroy point for item #{params[:id]} but no point found!"
        end
      end
    end
    redirect_to :controller => 'opportunity_list'
  end
  
  def validate_URL
    url_str = request.raw_post || request.query_string
    # this sets @results to OK or an error message
    validate_URL_str(url_str)
    render(:layout => false)
  end
  
  def validate_URL_str(url_str)
    Item.check_URL_str(url_str)
  end
  
  def test_URL
    url_str = request.raw_post || request.query_string
    Item.test_URL(url_str)
  end
 
  
end
