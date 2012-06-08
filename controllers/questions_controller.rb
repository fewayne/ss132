class QuestionsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @question_pages, @questions = paginate :question, :per_page => 10
  end

  def show
    @question = Question.find(params[:id])
  end

  def get_params
     if (params[:item_id])
         @item_id = params[:item_id]
     elsif (session[:item_id])
         @item_id = session[:item_id]
    end
    session[:item_id] = @item_id
    if (params[:uid])
         @uid = params[:uid]
    elsif (session[:uid])
         @uid = session[:uid]
    end
    session[:uid] = @uid
    # Setup the current question with item and user IDs
    if (@question != nil)
      if (@question.item == nil)
        begin
            @question.item = Item.find(session[:item_id])
        rescue
            flash[:notice] = "Could not find item from params"
        end
      end
      if (@question.user == nil)
        begin
            @question.user = User.find(session[:uid])
        rescue
            flash[:notice] = "Could not find uid from params"
        end
      end
    end
    
  end

  def new
    @question = Question.new
    get_params
    if Point.is_clobbered(@uid,@question.item.news_opportunity.id)
      flash[:error] = 'Your participation in this learning opportunity has been restricted. Please see your instructor.'
      redirect_to :action => 'show_error', :item_id => @question.item.id, :opp_id => @question.item.news_opportunity.id, :uid => @uid
      return
    end
  end

  def create
    logger.info "After munge filter, params are:\n#{params.inspect}"
    if params[:question]
      @question = Question.new(params[:question])
    elsif params['question']
      @question = Question.new(params[:question])
    elsif params['question%5Bquestion_text%5D']
      unmunge_brackets
      @question = Question.new(params[:question])
    elsif params['question[question_text]']
      @question = Question.new :question_text => params['question[question_text]']
      logger.info "funky params: #{params['question[question_text]']}"
    else
      flash[:error] = 'Sorry, but a bug in the software prevented your question from being recorded. Please try again.'
      logger.info "#{flash[:error]}, #{@uid}"
      redirect_to :action => :new
      return
    end
    get_params
    if Point.is_clobbered(@uid,@question.item.news_opportunity.id)
      flash[:error] = 'Your participation in this learning opportunity has been restricted. Please see your instructor.'
      redirect_to :action => 'show_error', :item_id => @question.item.id, :opp_id => @question.item.news_opportunity.id, :uid => @uid
      logger.info "#{flash[:error]}, #{@uid}"
      return
    end
    # it's not the *user's* item that's clobbered, but they're trying to post to a clobbered item.
    if @question.item.clobbered?
      flash[:error] = 'This item has been restricted by the instructors. Please choose another item.'
        redirect_to :action => 'show_error', :item_id => @question.item.id, :opp_id => @question.item.news_opportunity.id, :uid => @uid
        logger.info "#{flash[:error]}, #{@uid}"
        return
    end
    if (reasons = @question.item.question_posing_prohibited?(@uid))
      flash[:error] = 'You cannot pose a question to this item:<br/>  ' + reasons.join('  <br/>')
      redirect_to :action => 'show_error', :item_id => @question.item.id, :opp_id => @question.item.news_opportunity.id, :uid => @uid
      logger.info "#{flash[:error]}, #{@uid}"
      return
    end
    @question.posted = DateTime.now
    if @question.save
      flash[:notice] = 'Question was successfully created.'
      redirect_to :controller => 'item', :item => @item_id
    else
      flash[:notice] = "Sorry, there was a problem posting your question."
      logger.info "#{flash[:notice]}, #{@uid}, #{@question.errors.inspect}"
      render :action => 'new'
    end
  end

  def show_error
#    flash[:error] = '<br/>And your little dog, too!' if flash[:error] == nil || flash[:error] == ''
#    print "\n\n"
#    print flash[:error]
#    print "\n"
    begin
      @attempted_item = Item.find(params[:item_id])
      @opp = Opportunity.find(params[:opp_id])
      @me = User.find(params[:uid])
      @my_item = Item.find(:first, :conditions => ["news_opportunity_id = ? and user_id= ?",@opp.id,@me.id])
      @my_questions = Question.find_by_sql(
        "select * from questions,items where questions.item_id = items.id and items.news_opportunity_id = #{@attempted_item.news_opportunity_id}"
        )
    rescue Exception => e
      logger.warn 'question show_error boinked: item/op/user find failed!'
      logger.warn e.to_s
    end
  end
  
  def edit
    redirect_to :controller => 'item', :item => @item_id
#    @question = Question.find(params[:id])
  end

  def update
    redirect_to :controller => 'item', :item => @item_id
#    @question = Question.find(params[:id])
#    if @question.update_attributes(params[:question])
#      flash[:notice] = 'Question was successfully updated.'
#      redirect_to :action => 'show', :id => @question
#    else
#      render :action => 'edit'
#    end
  end

  def destroy
#    Question.find(params[:id]).destroy
#    redirect_to :action => 'list'
    redirect_to :controller => 'item', :item => @item_id
  end
end
