class NewsArticlesController < DocumentsController
  FORMAT_NAME = "news"

  def show
    @related_policies = @document.published_related_policies
    @document = NewsArticlePresenter.decorate(@document)
    set_slimmer_organisations_header(@document.organisations)
    set_slimmer_format_header(FORMAT_NAME)
  end

  private

  def document_class
    NewsArticle
  end
end
