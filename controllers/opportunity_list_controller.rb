class OpportunityListController < ApplicationController
  
  before_filter :instructors_only, :only => [:news_new, :news_create, :news_edit, :news_update, :destroy, :admin_list]
  
  def instructors_only
    @curUser = curUser
    unless @curUser.isInstructor
      flash[:notice] = 'Unauthorized'
      redirect_to :action => 'show_todays_opp'
    end
  end
    
  def index
    if (curUser.isInstructor)
      redirect_to :controller => 'grading'
      return
    end
    redirect_to :action => 'show_todays_opp'
  end

  def list
    @curUser = curUser
    @opportunity_pages, @opportunities = paginate :news_opportunity, :per_page => 1, :order => "phase_one_start DESC"
  end
  
  def show_todays_opp
    @curUser = curUser
    @opportunity,@opportunities = NewsOpportunity.todays_opp(Time.now)
  end
  
  def admin_list
    @news_opportunities = NewsOpportunity.find(:all, :order => :phase_one_start)
  end

  def news_show
    @curUser = curUser
    if params[:id] == nil
      @opportunity,@opportunities = NewsOpportunity.todays_opp(Time.now) || NewsOpportunity.find(:first)
    else
      @opportunity = NewsOpportunity.find(params[:id])
      @opportunities = NewsOpportunity.find(:all, :order => 'phase_one_start ASC, comments ASC')
    end
  end

  def news_new
    @opportunity = NewsOpportunity.new
    @opportunity.opportunity_number = NewsOpportunity.find_by_sql("select max(opportunity_number)+1 as next_opp_num from opportunities where type='NewsOpportunity'").first.next_opp_num
  end

  def news_create
    @opportunity = NewsOpportunity.new(params[:opportunity])
    @opportunity.set_times_from_phase_one
    if @opportunity.save
      flash[:notice] = 'News Opportunity was successfully created.'
    else
      flash[:notice] = 'News Opportunity could not be created.'
    end
    redirect_to :action => :admin_list
  end

  def news_edit
    @opportunity = NewsOpportunity.find(params[:id])
  end

  def news_update
    @opportunity = NewsOpportunity.find(params[:id])
    if @opportunity.update_attributes(params[:opportunity])
      flash[:notice] = 'News Opportunity was successfully updated.'
      redirect_to :action => 'admin_list'
    else
      render :action => 'news_edit'
    end
  end

  def destroy
    Opportunity.find(params[:id]).destroy
    redirect_to :action => 'admin_list'
  end
  
end
