# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_ss132_session_id'
  attr_accessor :nu_params
  
  # before_filter :unmunge_brackets
  
  def unmunge_brackets
    if params
      munge_encountered = false
      params.each_key do |key|
        if key =~ /^(.+)(%5B)(.+)(%5D)(%5B%5D)*$/
          unless munge_encountered
            munge_encountered = true
            logger.info "\n  Unmunging! Incoming: #{params.inspect}" 
          end
          value = params[key]    # e.g., the "502" in essay_point%5Buser_id%5D=>"502"
          params.delete(key)
          var_name = $1.to_sym   # s/b :essay_point
          attrib = $3     # :user_id or possibly keywords%5B%5D
          logger.info "  unmunge: after first round, key was #{key}, var name #{var_name}, attrib '#{attrib}'"
          if attrib =~ /(.+)%5D%5B$/ # Note how this is backwards from [], but it's OK!
            attrib = $1.to_sym # trim off the ugly
            logger.info "multivalued: attrib now #{attrib}, value #{value}"
            # if items are already in the list, add the new one
            if params[var_name] && params[var_name][attrib]
              value = params[var_name][attrib] + value
            else
              value = [value]
            end
          else
            attrib = attrib.to_sym
          end
          logger.info "other half of conditional (single-valued)"
          if params[var_name]    # if there already exist items in params[:essay_point]...
            (params[var_name]).merge!({attrib => value})
          else                   # if not, create one
            params[var_name] = {attrib => value}
          end
        end
      end
      logger.info "\n  Post-munge: #{params.inspect}" if munge_encountered
    else
      logger.info 'unmunge_brackets called, but no params!'
      logger.info "no params"
    end
    return true
  end
  
  def extract_netid_from_shibboleth(request)
    if RAILS_ENV == 'test' || RAILS_ENV == 'development'
      ret = User.find_by_isInstructor(1).netID
      logger.debug "extract_netid: returning user #{ret.inspect}"
      return(ret)
    else
      return request.env['uid']
    end
    raise 'Should never get here'
  end
  
  def userNetID
    netid = session[:netid] || extract_netid_from_shibboleth(request) || UNKNOWN_USER_ID
    session[:netid] = netid
  end
  
  def curUser
    user = User.find(:first, :conditions => ["netID = ?",userNetID])
    if user == nil
      logger.warn "Could not find netID '#{userNetID}' in the database!"
    end
    user
  end
  
  def opp_str(opp_type)
    if (opp_type.include? "Opportunity")
      opp_type
    else
      "#{opp_type}Opportunity"
    end
  end
  
  def get_user_id
    curUser.id
  end

  def log_user
    logger.info "  This is #{userNetID}"
  end
  
  def bump_em
    @curUser = curUser
    authorized = @curUser && @curUser.is_instructor
    unless authorized
      redirect_to :controller => 'opportunity_list'
    end
    authorized
  end
  
  def todays_page(opp_type,today=Time.now)
    logger.info "application::todays_page called for #{opp_type}, today is #{today.to_s}"
    if opp_type == 'News'
      current_op,opps = NewsOpportunity.todays_opp(today)
    else
      current_op,opps = Opportunity.todays_opp(today)
    end
    unless current_op
      logger.info 'application#todays_page: could not find a current opp, going to first one in the list'
      opps = Opportunity.find(:all, :conditions => ["type = ?",opp_str(opp_type)], :order => 'phase_one_start ASC')
      current_op = opps.first
    end
    current_op.opportunity_number.to_i
  end
 
  def pagenum_for(opp,opps)
    (opp && opps) ? (opps.size + 1) - opp.opportunity_number.to_i : 1
  end
   
  def student_list
    User.find(:all,:order => 'full_name', :conditions => ['isInstructor = ?',0])
  end


end
