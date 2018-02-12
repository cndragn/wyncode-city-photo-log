class PicturesController < ApplicationController

  before_action :find_picture, only: [:show, :edit, :update, :destroy]

  # GET /pictures
  # GET /pictures.json
  def index
    if params[:location].blank?
    @pictures = Picture.all.order("created_at DESC")
  else
    @location_id = Location.find_by(name: params[:location]).id
    @pictures = Picture.where(:location_id => @location_id).order("created_at DESC")
  end


    @cityQuery = "Dubai"
    cat = "landmarks"

    @citySelect = @cityQuery.split(",")[0]

    # Start of destination scrape
    destUrl = "http://www.10best.com/destinations/all/"

    destResponse = HTTParty.get(destUrl)
    # p response.headers['Content-Type']

    #String => Nokgiri::HTML => DocumentObjectModel (DOM)
    destDom = Nokogiri::HTML(destResponse.body)
    # p dom.css('html') #gives everything wthin the html tag

    destinations = destDom.css('a.rss')

    @cities = []
    destinations.each do |city|
      @cities << city.text
    end

    @links = []
    destinations.each do |link|
      @links << 'http://www.10best.com' + link['href']
    end
    # End of destination scrape

    @cityIndex = @cities.index(@cityQuery)

    # Start of attractions scrape
    @attrUrl = @links[@cityIndex] + "attractions/best-attractions-activities/"

    attrResponse = HTTParty.get(@attrUrl)

    #String => Nokgiri::HTML => DocumentObjectModel (DOM)
    attrDom = Nokogiri::HTML(attrResponse.body)
    # p dom.css('html') #gives everything wthin the html tag

    attractions = attrDom.css('.list-headline h2')

    @venue = []
    attractions.each do |place|
      @venue << place.text
    end

    # Get two random attractions and give them their own variables
    @venues = @venue.sample(2)
    @venue_one = @venues[0]
    @venue_two = @venues[1]

    # Index of random photo to grab correct picture
    @index_one = @venue.index(@venue_one)
    @index_two = @venue.index(@venue_two)

    images = attrDom.css('img.lazy')

    @image = []
    images.each do |picture|
      @image << 'https:' + picture['data-src']
    end

    # Select image link based on index of random photo
    @image_one = @image[@index_one]
    @image_two = @image[@index_two]
    # End of attractions scrape

    # PHOTO VARIABLES



      # @cityIndex = @cities.index(cityQuery)

    # Start of Flickraw API
    FlickRaw.api_key="3d403357fbd5a290f43a9b6cd0216a4a"
    FlickRaw.shared_secret="7ea1e588cac6c790"

    args = {:tags => "#{@citySelect} #{cat}" }

    @flickrsearch = []

    discovered_pictures = flickr.photos.search args
    discovered_pictures.each{|p| url = FlickRaw.url p; @flickrsearch << url}

    # @flickrpics = @flickrsearch.map {|f| "<img src='#{f}'>"}

    # End of Flickraw API

  end

  # GET /pictures/1
  # GET /pictures/1.json
  def show
  end

  # GET /pictures/new
  def new
		@picture = current_user.pictures.build
		@categories = Location.all.map{ |c| [c.name, c.id] }
	end

	def create
		@picture = current_user.pictures.build(picture_params)
		@picture.location_id = params[:location_id]

		if @picture.save
			redirect_to root_path
		else
			render 'new'
		end
	end

  # PATCH/PUT /pictures/1
  def edit
    @locations = Location.all.map{ |l| [l.name, l.id]}
  end
  # PATCH/PUT /pictures/1.json
  def update
    respond_to do |format|
      if @picture.update(picture_params)
        format.html { redirect_to @picture, notice: 'Picture was successfully updated.' }
        format.json { render :show, status: :ok, location: @picture }
      else
        format.html { render :edit }
        format.json { render json: @picture.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pictures/1
  # DELETE /pictures/1.json
  def destroy
    @picture.destroy
    respond_to do |format|
      format.html { redirect_to pictures_url, notice: 'Picture was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def find_picture
    @picture = Picture.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def picture_params
    params.require(:picture).permit(:title, :url, :pic_img, :location)
  end
end