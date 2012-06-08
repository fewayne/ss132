class ItemController < ApplicationController
  
  before_filter :log_user
  
  def max_questions
    3 
  end

  def index
    @uid = curUser.id
    @item_id = params[:item]
    session[:item_id] = @item_id
    # Strip bad stuff from parameter here!
    begin
     @item = Item.find(@item_id)
     if @item.clobbered?
       flash[:error] = "Access to this item has been restricted. Contact your instructor."
     end
    rescue
     flash[:note] = "No item found for item_id #{@item_id}"
    end
  end

  def question_posing_prohibited?(uid)
    @item.question_posing_prohibited?(uid)
  end

end
