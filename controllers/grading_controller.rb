class GradingController < ApplicationController
  before_filter :bump_em
  
  def index
    @curUser = curUser
    @users = student_list
  end
  def new_news
    @opportunity = NewsOpportunity.new
  end

  def create_news
    @opportunity = NewsOpportunity.new(params[:opportunity])
    if @opportunity.save
      flash[:notice] = 'Opportunity was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit_news
    @opportunity = NewsOpportunity.find(params[:id])
  end

  def update_news
    @opportunity = NewsOpportunity.find(params[:id])
    if @opportunity.update_attributes(params[:opportunity])
      flash[:notice] = 'Opportunity was successfully updated.'
      redirect_to :action => 'list', :id => @opportunity
    else
      render :action => 'edit'
    end
  end

  def destroy_news
    NewsOpportunity.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def self.hdrs
    if @hdrs == nil
      @hdrs =
        [
          ["StudentId",''],
          ["Username",''],
    #      "Midterm#1 Out Of Grade",
    #      "Midterm#2 Out Of Grade",
    #      "Midterm#3 Out Of Grade",
    #      "SummaryExam Out Of Grade",
          ["Letters Out Of Grade",'Essay'],
          ["News Out Of Grade",'News'],
          ["Labs Out Of Grade",'Lab'],
          ["Science Literature Out Of Grade",'ScienceLit'],
          ["Popular Media Out Of Grade", 'PopularMedia'],
          ["Science At Work Out Of Grade", 'SciAtWork']
    #      ["Calculations Out Of Grade",'Calcs']
    #      "Adjusted Final Grade"
        ]
    end
    @hdrs
  end

  def self.header_line
    # hdrs.join(',')
    "Username,Letters Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,News Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,Labs Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,Science Literature Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,Popular Media Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,Water Sci Work Points Grade <Numeric MaxPoints:12 Category:Learning Activities>,End-of-Line Indicator"
  end
  
  SHORT_NAME = 1
  LONG_NAME = 0
  
  def each_long_name
    GradingController.hdrs.each do |hdr_arr|
      yield hdr_arr[LONG_NAME]
    end
  end
  
  def each_short_name
    GradingController.hdrs.each do |hdr_arr|
      yield hdr_arr[SHORT_NAME] unless hdr_arr[SHORT_NAME] == ''
    end
  end
      
  def show_one_student
    user_id = params[:id]
    # Have to have special logic here: Users can view their own grades
    @viewing_user = curUser
    if @viewing_user.id.to_s != user_id
      redirect_to :controller => 'opportunity_list' unless @viewing_user.is_instructor
    end
    @user = User.find(user_id)
  end

  def get_point_strs
    point_strs = Array.new
    mesg = ""
    
    each_long_name {|long_name| if mesg != "" then mesg += ',' end; mesg += long_name}
    
    point_strs << GradingController.header_line
    User.find(:all,:conditions => ["isInstructor = ? and student_id is not null",0], :order => "student_id ASC").each do |user|
      mesg = "#{user.netID}"
      each_short_name do |short_name|
        mesg += ",#{Point.total_points_for_user_by_opp_type(user.id,short_name)}"
      end
      mesg += ",\#"
      point_strs << mesg
    end
    point_strs
  end
  
  def export
    bump_em
    @point_strs = get_point_strs
    send_data(@point_strs.join("\r\n"),
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :filename => 'import.csv')
  end
  
end
