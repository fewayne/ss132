class EssayTopicsController < ApplicationController
  before_filter :bump_em, :except => [:index, :list]
  def index
    list
    render :action => 'list'
  end

  def list
    @essay_opportunity_pages, @essay_opportunitys = paginate :opportunities, :per_page => 20, :conditions => "type = 'EssayOpportunity'"
  end

  def show
    @essay_opportunity = EssayOpportunity.find(params[:id])
  end

  def new
    @essay_opportunity = EssayOpportunity.new
  end

  def create
    @essay_opportunity = EssayOpportunity.new(params[:essay_opportunity])
    if @essay_opportunity.save
      flash[:notice] = 'EssayOpportunity was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @essay_opportunity = EssayOpportunity.find(params[:id])
  end

  def update
    @essay_opportunity = EssayOpportunity.find(params[:id])
    if @essay_opportunity.update_attributes(params[:essay_opportunity])
      flash[:notice] = 'EssayOpportunity was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    EssayOpportunity.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
