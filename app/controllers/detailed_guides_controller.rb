require 'gds_api/helpers'
require 'gds_api/content_api'

class DetailedGuidesController < DocumentsController
  include GdsApi::Helpers
  layout "detailed-guidance"
  before_filter :set_search_path
  before_filter :set_artefact, only: [:show]

  respond_to :html, :json

  def index
    params[:page] ||= 1
    params[:direction] = "alphabetical"
    @filter = Whitehall::DocumentFilter.new(all_detailed_guides, params)
    respond_with DetailedGuideFilterJsonPresenter.new(@filter)
  end

  def show
    @categories = @document.mainstream_categories
    @topics = @document.topics
    render action: "show"
  end

  def search
    @search_term = params[:q]
    mainstream_results = Whitehall.mainstream_search_client.search(@search_term)
    @mainstream_results = mainstream_results.take(5)
    @more_mainstream_results = mainstream_results.length > 5
    @results = Whitehall.search_client.search(@search_term, 'detailed_guidance').take(50 - @mainstream_results.length)
    @total_results = @results.length + @mainstream_results.length
    respond_with @results
  end

  def autocomplete
    render text: Whitehall.search_client.autocomplete(params[:q], 'detailed_guidance')
  end

private
  def document_class
    DetailedGuide
  end

  def all_detailed_guides
    DetailedGuide.published.includes(:document, :organisations, :topics)
  end

  def set_search_path
    response.headers[Slimmer::Headers::SEARCH_PATH_HEADER] = search_detailed_guides_path
  end

  def set_proposition
    set_slimmer_headers(proposition: "specialist")
  end

  def set_artefact
    if artefact_hash = @document.to_artefact_hash(content_api)
      set_slimmer_artefact artefact_hash
    end
  end

end
