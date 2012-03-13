class MygamesController < ApplicationController
  before_filter :require_fb_user
  # GET /mygames
  # GET /mygames.json
  def index
    @mygames = Mygame.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mygames }
    end
  end

  # GET /mygames/1
  # GET /mygames/1.json
  def show
    @mygame = Mygame.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mygame }
    end
  end

  # GET /mygames/new
  # GET /mygames/new.json
  def new
    @mygame = Mygame.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mygame }
    end
  end

  # GET /mygames/1/edit
  def edit
    @mygame = Mygame.find(params[:id])
  end

  # POST /mygames
  # POST /mygames.json
  def create
    appids = params[:appids]
    games = appids.blank? ? [] : Game.find(:all, :conditions=>"app_id in (#{appids})")
    fb_user.games = games
    render :nothing=>true
  end

  # PUT /mygames/1
  # PUT /mygames/1.json
  def update
    @mygame = Mygame.find(params[:id])

    respond_to do |format|
      if @mygame.update_attributes(params[:mygame])
        format.html { redirect_to @mygame, notice: 'Mygame was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @mygame.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mygames/1
  # DELETE /mygames/1.json
  def destroy
    @mygame = Mygame.find(params[:id])
    @mygame.destroy

    respond_to do |format|
      format.html { redirect_to mygames_url }
      format.json { head :no_content }
    end
  end
end
