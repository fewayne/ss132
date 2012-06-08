class GradeOtherActivitiesController < ApplicationController
  before_filter :bump_em

  STUDENTS_PER_PAGE = 40
  BAD_DECODE = -99
  def index
    @learning_opportunities = Opportunity.find(:all, :conditions => "type not like 'News%' and type not like 'Essay%'", :order => 'type ASC, opportunity_number ASC')
    @users = student_list
  end
  
  def grade
    id = params[:id]
    @learning_opportunity = Opportunity.find(id) if id != nil
    @users_per_page = STUDENTS_PER_PAGE
    @student_list = student_list
    @user_pages,@users = paginate :users, :per_page => STUDENTS_PER_PAGE, :conditions => ['isInstructor = ?',0], :order => 'full_name ASC'
    @user_points,@point_recs = user_points(@users,@learning_opportunity)
  end
  
  def assign_points
    row = 0
    # obtain the whole student list
    @users = student_list
    if ((first_point_param = params[:pointsParam_0]) == nil)
      return @results = "Could not get first row"
    end
    learning_opportunity_id = first_point_param.split(/_/)[1]
    @learning_opportunity = Opportunity.find(learning_opportunity_id)
    # create a Hash by student id of the point records of all students participating in this opportunity
    @user_points,@point_recs = user_points(@users,@learning_opportunity)
    while ((points_str = params["pointsParam_#{row}"]) != nil)
      if points_str != nil
        # but points comes in as a separate param under CGI
        points = params["points_#{row}"] || 0.to_s
        points_str = points+"_"+points_str
        ajax = false
      else
        points_str = request.raw_post || request.query_string
        ajax = true
      end
      points_arr = decode(points_str)
      points = points_arr[0]
      user_id = points_arr[1]
      learning_opportunity_id = points_arr[2]

      begin
        points = points.to_i
      rescue
        bad_points_name = (@users.select {|user| user.id = user_id}).first
        mesg = " points value for #{bad_points_name} was not a number, skipping"
        flash[:error] = (flash[:error] == nil) ? mesg : flash[:error] + mesg
      else # only execute this if no exception, i.e. points is a valid integer
        # Lab Opportunities allow point values of -2; others (so far) have a floor of 0
        if @learning_opportunity.is_a? LabOpportunity
          points = -2 if points < -2
        else
          points = 0 if points < 0
        end
        points = @learning_opportunity.max_final_points if points > @learning_opportunity.max_final_points
        if user_id == BAD_DECODE || learning_opportunity_id == BAD_DECODE || points == BAD_DECODE
          return @results = "Malformed input: #{points_str}"
        end
        point_record = (@point_recs.select {|point| point.user_id == user_id}).first
        if point_record == nil
          point_record = new_point(user_id,learning_opportunity_id,points)
        else
          point_record.final_points = points
        end
        begin
          point_record.save!
        rescue
          return @results = "Database error: #{$!}"
        end
        @user_points[user_id] = points
      end # else clause of rescue; in either case, increment and go 'round again
      row += 1
    end
    @results = "OK"
    if !ajax
     redirect_to(:controller => 'grade_other_activities', :action => 'grade', :id => learning_opportunity_id)
    end
  end

# Remainder of methods are helpers
private

  def user_points(users,opp)
    user_points = Hash.new
    users.each {|user| user_points[user.id] = 0}
    point_recs = Point.find(:all, :conditions => ["opportunity_id = ?",opp.id])
    point_recs.each {|point| user_points[point.user_id] = point.final_points}
    [user_points,point_recs]
  end

    # parse a string sent by GradeOtherActivitiesHelper::encode; return array => [id,value]
    def decode(str)
      res = [BAD_DECODE,BAD_DECODE,BAD_DECODE]
      fields = str.split(/_/)
      return res if fields.size != 3
      fields.collect { |field| field.to_i }
    end
  
    def new_point(u_id,opp_id,points)
      p = Point.new
      p.user_id = u_id
      p.opportunity_id = opp_id
      p.final_points = points
      p
    end
  

  def add_points(id,points,category_str)
    @points_hashes = Hash.new if @points_hashes == nil
    point_hash = Hash.new if (point_hash = @points_hashes[id]) == nil
    if point_hash[category_str] == nil
      point_val = 0
    else
      point_val = point_hash[category_str].to_i
    end
    point_val += points.to_i
    point_hash[category_str] = point_val
    @points_hashes[id] = point_hash
  end

  def add_other_points(descr,category_str)
    query = <<-HERE
      select student_id,sum(points) as total from users,other_activity_points oap,learning_opportunities lo
      where users.id = oap.user_id and oap.learning_opportunity_id = lo.id and lo.description like "%s %%" 
      and student_id is not null group by users.id
    HERE
    query = sprintf(query,descr)
    points = User.find_by_sql(query)
    for point in points 
      add_points(point.student_id,point.total,category_str)
    end
  end

  def ltrs_points
    ltr_header = 1
    ltrs_points = User.find_by_sql("select distinct student_id,sum(final_points) as total from users,essays where users.id=essays.user_id and student_id is not null group by users.id")
    for point in ltrs_points
      add_points(point.student_id,point.total,@hdrs[ltr_header])
    end
  end

  def itn_points
    itn_header = 2
    itn_points = User.find_by_sql("select distinct student_id,news_opportunity_id,final_points from users,points where users.id=points.user_id and student_id is not null order by student_id asc")
    for point in itn_points
      add_points(point.student_id,point.final_points,@hdrs[itn_header])
    end
  end

  def other_points
    other_headers = 3..5
    @hdrs[other_headers].each do |category_str|
      category_str =~ /([A-Z][a-z-]+)[^a-z-]/
      add_other_points($1,category_str)
    end
  end

  def point_str(user)
    str = "\##{user.student_id}"
    point_hash = Hash.new if (point_hash = @points_hashes[user.student_id]) == nil
    @hdrs[1 , 5].each do |header_str|
      points = point_hash[header_str]
      if points == nil
        this_activity_point_str = ""
      else
        this_activity_point_str = points.to_s
      end
      str = str + ",#{this_activity_point_str}"
    end
    str = str + "\#"
  end

  def build_point_strs
    @point_strs = Array.new
    for user in @users
      if user.student_id != nil && user.student_id != ""
        @point_strs << point_str(user)
      end
    end
  end
  
end
