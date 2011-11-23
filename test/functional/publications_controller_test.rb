require "test_helper"

class PublicationsControllerTest < ActionController::TestCase
  test "should only display published publications" do
    archived_publication = create(:archived_publication)
    published_publication = create(:published_publication)
    draft_publication = create(:draft_publication)
    get :index

    assert_select_object(published_publication)
    assert_select_object(archived_publication, count: 0)
    assert_select_object(draft_publication, count: 0)
  end

  test 'show displays published publications' do
    published_publication = create(:published_publication)
    get :show, id: published_publication.document_identity
    assert_response :success
  end

  test 'show displays related published policies' do
    published_policy = create(:published_policy)
    publication = create(:published_publication, documents_related_to: [published_policy])
    get :show, id: publication.document_identity
    assert_select_object published_policy
  end

  test 'show doesn\'t display related but unpublished policies' do
    draft_policy = create(:draft_policy)
    publication = create(:published_publication, documents_related_to: [draft_policy])
    get :show, id: publication.document_identity
    assert_select_object draft_policy, count: 0
  end

  test "should show inapplicable nations" do
    published_publication = create(:published_publication)
    northern_ireland_inapplicability = published_publication.nation_inapplicabilities.create!(nation: Nation.northern_ireland, alternative_url: "http://northern-ireland.com/")
    scotland_inapplicability = published_publication.nation_inapplicabilities.create!(nation: Nation.scotland)

    get :show, id: published_publication.document_identity

    assert_select inapplicable_nations_selector do
      assert_select "p", "This publication does not apply to Northern Ireland and Scotland."
      assert_select_object northern_ireland_inapplicability do
        assert_select "a[href='http://northern-ireland.com/']"
      end
      assert_select_object scotland_inapplicability, count: 0
    end
  end

  test "should explain that publication applies to the whole of the UK" do
    published_publication = create(:published_publication)

    get :show, id: published_publication.document_identity

    assert_select inapplicable_nations_selector do
      assert_select "p", "This publication applies to the whole of the UK."
    end
  end

  test "should display PDF attachment metadata" do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attachment = create(:attachment, file: greenpaper_pdf)
    publication = create(:published_publication, attachments: [attachment])

    get :show, id: publication.document_identity

    assert_select_object(attachment) do
      assert_select ".type", "PDF"
      assert_select ".number_of_pages", "1 page"
      assert_select ".size", "3.39 KB"
    end
  end

  test "should display non-PDF attachment metadata" do
    csv = fixture_file_upload('sample-from-excel.csv', 'text/csv')
    attachment = create(:attachment, file: csv)
    publication = create(:published_publication, attachments: [attachment])

    get :show, id: publication.document_identity

    assert_select_object(attachment) do
      assert_select ".type", "CSV"
      assert_select ".number_of_pages", count: 0
      assert_select ".size", "121 Bytes"
    end
  end
end
