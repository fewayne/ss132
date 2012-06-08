class QResponsesController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @q_response_pages, @q_responses = paginate :q_response, :per_page => 10
  end

  def show
    @q_response = QResponse.find(params[:id])
  end

  def setup_refs
    @q_response.question_id = session[:response_qid]
    @q_response.user_id = session[:response_uid]
    @q_response.posted = Time.now
    @question = Question.find(@q_response.question_id)
    @item = @question.item
  end

  def new
    @q_response = QResponse.new
    session[:response_qid] = params[:qid]
    # Why am I dinking around with this? Why not just use get_user_id?
    session[:response_uid] = params[:uid]
    setup_refs
    if Point.is_clobbered(@q_response.user_id,@question.item.news_opportunity.id)
      flash[:notice] = 'Your participation in this learning opportunity has been restricted. Please see your instructor.'
      redirect_to :controller => 'opportunity_list'
      return
    end
    
  end

  def create
    @q_response = QResponse.new(params[:q_response])
    setup_refs
    if Point.is_clobbered(@q_response.user_id,@question.item.news_opportunity.id)
      flash[:notice] = 'Your participation in this learning opportunity has been restricted. Please see your instructor.'
      redirect_to :controller => 'opportunity_list'
      return
    end
    already = QResponse.find_by_user_id_and_question_id(@q_response.user_id,@q_response.question_id)
    if already != nil
      flash[:notice] = 'You have already responded to this question.'
      redirect_to :controller => 'item', :item => @q_response.question.item_id
    elsif @q_response.save
      flash[:notice] = 'Your response has been recorded.'
      redirect_to :controller => 'item', :item => @q_response.question.item_id
    else
      flash[:notice] = 'Sorry, there was a problem posting your response.'
      render :action => 'new'
    end
  end

  def edit
    redirect_to :controller => 'item', :item => @q_response.question.item_id
#    @q_response = QResponse.find(params[:id])
  end

  def update
    redirect_to :controller => 'item', :item => @q_response.question.item_id
#    @q_response = QResponse.find(params[:id])
#    if @q_response.update_attributes(params[:q_response])
#      flash[:notice] = 'QResponse was successfully updated.'
#      redirect_to :controller => 'item'
#    else
#      render :action => 'edit'
#    end
  end

  def destroy
#    QResponse.find(params[:id]).destroy
#    redirect_to :action => 'list'
    redirect_to :controller => 'item', :item => @q_response.question.item_id
  end
end
