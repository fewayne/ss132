class SciAtWorkController < EssaysController

  SCI_POINT_QUERY = "select p.*,o.opportunity_number,u.full_name from points p, opportunities o, users u where o.type = 'SciAtWorkOpportunity' and p.opportunity_id = o.id and p.user_id = u.id order by opportunity_number desc, (final_points IS NULL) desc,phase_one_instr_id asc,full_name"

  def grade_one
    if params[:id]
      @opportunity = SciAtWorkOpportunity.find(params[:id])
      @opportunities = SciAtWorkOpportunity.find(:all, :order => 'phase_one_start, comments asc')
    else
      @opportunity,@opportunities = SciAtWorkOpportunity.todays_opp
      @opportunity = SciAtWorkOpportunity.last_opp                 
    end
    @opportunity ||= SciAtWorkOpportunity.find(:first)
    @opportunities = SciAtWorkOpportunity.find(:all) unless @opportunities.size > 0
    @essay_points = Point.find_by_sql(SCI_POINT_QUERY)
    raise "no opportunity" unless @opportunity
    raise "no list of opportunities" unless @opportunities && @opportunities.size > 0
    render 'essays/grade_one.rhtml'
  end
  
  def update
    @essay_point = Point.find(params[:id])
    if @essay_point.update_attributes(params[:essay_point])
      flash[:notice] = 'Record was successfully updated.'
      redirect_to :controller => 'sci_at_work'
    else
      render :action => 'edit'
    end
  end

  
end
