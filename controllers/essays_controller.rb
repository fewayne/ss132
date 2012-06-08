class EssaysController < ApplicationController
  before_filter :bump_em
  POINT_QUERY = "select p.*,o.opportunity_number,u.full_name from points p, opportunities o, users u where o.type = 'EssayOpportunity' and p.opportunity_id = o.id and p.user_id = u.id order by opportunity_number desc, (final_points IS NULL) desc,phase_one_instr_id asc,full_name"
  def index
    list
    redirect_to :action => 'list', :page => todays_page('Essay')
  end
  
  def grade_one
    if params[:id]
      @opportunity = EssayOpportunity.find(params[:id])
      @opportunities = EssayOpportunity.find(:all, :order => 'phase_one_start, comments asc')
    else
      @opportunity,@opportunities = EssayOpportunity.todays_opp
      @opportunity = EssayOpportunity.last_opp
    end
    @essay_points = Point.find_by_sql(POINT_QUERY)
  end

  def list
    @essay_opportunity_pages, @essay_opportunities = paginate :EssayOpportunity, :per_page => 1, :order => "phase_one_start asc"
   # @essay_point_pages, @essay_points = paginate :essay_point, :per_page => 30, :joins => "left join opportunities o on o.id = opportunity_id", :order => 'o.opportunity_number desc'
    @essay_points = Point.find_by_sql(POINT_QUERY)
  end

  def show
    @essay_point = Point.find(params[:id])
  end
  
  def new
    @essay_point = Point.new :opportunity_id =>  params[:opp], :phase_one_instr_id => curUser.id, :initial_points => 0
  end

  def create
    @essay_point = Point.new(params[:essay_point])
    if params[:stunningly_good] == "1"
      # Initial points aren't counted in the scoring, but set them just for consistency
      @essay_point.initial_points = @essay_point.opportunity.max_initial_points
      @essay_point.final_points = @essay_point.opportunity.max_final_points
    end
    # If this is a Popular Media opp and it's "books", there is only one grading step, so 
    # set final_points too
    if @essay_point.opportunity['type'] =~ /PopularMedia/ && @essay_point.opportunity['comments'] =~ /Books/
      @essay_point.final_points = @essay_point.initial_points
      @essay_point.initial_points = 0
    end
    if ((already = Point.find(:first,:conditions => ["opportunity_id = ? and user_id = ?",@essay_point.opportunity_id,@essay_point.user_id])))
      link_text = "<a href='\##{already.student.id}'>(jump there)</a>"
      flash[:error] = "Student #{already.student.full_name} already has an essay recorded for this opportunity #{link_text}!"
      redirect_to :action => 'grade_one', :id => @essay_point.opportunity_id
      return
    end
    
    if @essay_point.save
      flash[:notice] = 'Draft grade recorded.'
      if params[:stunningly_good] == "1"
        flash[:notice] += ' Final and initial assigned, so no rewrite should be required.'
      end
      redirect_to :action => 'grade_one', :id => @essay_point.opportunity_id
    else
      render :action => 'new'
    end
  end

  def edit
    @essay_point = Point.find(params[:id])
    @essay_point.phase_two_instr_id = @essay_point.phase_two_instr_id || curUser.id
    # this is redundant unless we're coming in from the Popular Media controller
    render :action => '../essays/edit'
  end

  def update
    @essay_point = Point.find(params[:id])
    if @essay_point.update_attributes(params[:essay_point])
      flash[:notice] = 'Essay was successfully updated.'
      redirect_to :action => 'list', :page => params[:page] 
    else
      render :action => 'edit'
    end
  end

  def destroy
    if (point = Point.find(params[:id]))
      point.destroy
    end
    redirect_to :action => 'list', :page => params[:page]
  end
  
  
end
