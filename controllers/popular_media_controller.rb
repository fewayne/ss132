class PopularMediaController < EssaysController

  PM_POINT_QUERY = "select p.*,o.opportunity_number,u.full_name from points p, opportunities o, users u where o.type = 'PopularMediaOpportunity' and p.opportunity_id = o.id and p.user_id = u.id order by opportunity_number desc, (final_points IS NULL) desc,phase_one_instr_id asc,full_name"

  def grade_one
    if params[:id]
      @opportunity = PopularMediaOpportunity.find(params[:id])
      @opportunities = PopularMediaOpportunity.find(:all, :order => 'phase_one_start, comments asc')
    else
      @opportunity,@opportunities = PopularMediaOpportunity.todays_opp
      @opportunity = PopularMediaOpportunity.last_opp                 
    end
    @opportunity ||= PopularMediaOpportunity.find(:first)
    @essay_points = Point.find_by_sql(PM_POINT_QUERY)
    raise "no opportunity" unless @opportunity
    raise "no list of opportunities" unless @opportunities
    render 'essays/grade_one.rhtml'
  end
  
  def update
    @essay_point = Point.find(params[:id])
    if @essay_point.update_attributes(params[:essay_point])
      flash[:notice] = 'Essay was successfully updated.'
      redirect_to :controller => 'popular_media'
    else
      render :action => 'edit'
    end
  end

  
end
