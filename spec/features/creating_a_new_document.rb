require 'spec_helper'
require 'pry'

RSpec.feature "Creating a new document", type: :feature do
  def cma_case_content_item_links
    {
        "content_id" => "4a656f42-35ad-4034-8c7a-08870db7fffe",
        "links" => {
            "organisations" => ["957eb4ec-089b-4f71-ba2a-dc69ac8919ea"]
        }
    }
  end 
  # TODO: How to generalise this bit?
  let(:cma_case) { FactoryGirl.create(:cma_case)}
  let(:content_id) { cma_case['content_id'] }
  let(:save_button_disable_with_message) { page.find_button('Save as draft')["data-disable-with"] }

  # save_button = "Save as draft"
  # add_link = "Add another CMA Case"
  # document_root = "/cma-cases"

  before do
    log_in_as_editor(:cma_case)

    allow(SecureRandom).to receive(:uuid).and_return(content_id)
    Timecop.freeze(Time.parse("2015-12-03 16:59:13 UTC"))

    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links

    publishing_api_has_content([cma_case], hash_including(document_type: CmaCase.document_type))
    publishing_api_has_item(cma_case)
  end

  scenario "getting to the new document page" do
    visit "/cma-cases"
    click_link "Add another CMA Case"

    expect(page.status_code).to eq(200)
    expect(page.current_path).to eq("/cma-cases/new")
  end

  # scenario "Add a New Document" do
  #   visit document_root
  #   click_link add_link
  #
  #   expect_page_to_have_common_content
  #
  #   enter_no_data_for_common_fields
  #   enter_no_data_for_specific_fields         # abstract away somehow
  #
  #   expect(save_button_disable_with_message).to eq("Saving...")
  #
  #   click_button save_button
  #
  #   expect_no_data_for_common_fields
  #   expect_no_data_for_specific_fields        # abstract away somehow
  #
  #   enter_invalid_data_for_common_fields
  #   enter_invalid_data_for_specific_fields    # abstract away somehow
  #
  #   click_button save_button
  #
  #   expect_invalid_data_for_common_fields
  #   expect_invalid_data_for_specific_fields   # abstract away somehow
  #
  #   enter_valid_data_for_common_fields
  #   enter_valid_data_for_specific_fields      # abstract away somehow
  #
  #   click_button save_button
  #
  #   expect_valid_data_for_common_fields
  #   expect_valid_data_for_specific_fields     # abstract away somehow
  #
  #   expect_draft_document_page_state
  #
  #   expect(page.status_code).to eq(200)
  #   expect(page).to have_content("Created Example Document")
  #   expect(page).to have_content('Bulk published false')
  # end

  def expect_page_to_have_common_content
    expect(page).to have_css('div.govspeak-help')
    expect(page).to have_content('To add an attachment, please save the draft first.')
  end

  def enter_no_data_for_common_fields
    fill_in "Title", with: ""
    fill_in "Summary", with: ""
    fill_in "Body", with: ""
  end

  def expect_no_data_for_common_fields
    expect(page.status_code).to eq(422)

    expect(page).to have_css('.elements-error-summary')
    expect(page).to have_css('.form-group.elements-error')
    expect(page).to have_css('.elements-error-message')

    expect(page).to have_content("Please fix the following errors")
    expect(page).to have_content("Title can't be blank")
    expect(page).to have_content("Summary can't be blank")
    expect(page).to have_content("Body can't be blank")
  end

  def enter_valid_data_for_common_fields
    fill_in "Title", with: "Example Document"
    fill_in "Summary", with: "This is the summary of an example Document"
    fill_in "Body", with: "## Header" + ("\n\nThis is the long body of an example Document" * 2)
  end

  def expect_valid_data_for_common_fields
    expect(page).to_not have_css('.elements-error-summary')
    expect(page).to_not have_css('.form-group.elements-error')
    expect(page).to_not have_css('.elements-error-message')

    expect(page).to_not have_content("Please fix the following errors")
    expect(page).to_not have_content("Title can't be blank")
    expect(page).to_not have_content("Summary can't be blank")
    expect(page).to_not have_content("Body can't be blank")
  end

  def enter_invalid_data_for_common_fields
    fill_in "Title", with: "Example CMA Case"
    fill_in "Summary", with: "This is the summary of an example CMA case"
    fill_in "Body", with: "<script>alert('hello')</script>"
  end

  def expect_invalid_data_for_common_fields
    expect(page.status_code).to eq(422)

    expect(page).to have_css('.elements-error-summary')
    expect(page).to have_css('.elements-error-message')

    expect(page).to have_content("Please fix the following errors")
    expect(page).to have_content("Opened date should be formatted YYYY-MM-DD")
    expect(page).to have_content("Body cannot include invalid Govspeak")
  end

  def expect_draft_document_page_state
    expect(page).to_not have_selector(:link_or_button, "View on website")
    expect(page).to have_selector(:link_or_button, "Preview draft")
    expect(page).to have_selector(:link_or_button, "Publish")
    expect(page).to_not have_selector(:link_or_button, "Unpublish")
    expect(page.find(:css, "dl.metadata-list").find("span.label").text).to eq('draft')
  end


  # Document specific parts of the test


  def enter_no_data_for_specific_fields
    fill_in "Opened date", with: ""
    # unselect "*", from: "Market sector"
    # fill_in "Market sector", with: ""
    find_field("Market sector").text ""
  end

  def expect_no_data_for_specific_fields
    expect(page).to have_content("Market sector can't be blank")
  end

  def enter_valid_data_for_specific_fields
    fill_in "Opened date", with: "2014-01-01"
    select "Energy", from: "Market sector"
  end

  def expect_valid_data_for_specific_fields
    expect(page).to_not have_content("Please fix the following errors")
    expect(page).to_not have_content("Opened date should be formatted YYYY-MM-DD")
    expect(page).to_not have_content("Body cannot include invalid Govspeak")
  end

  def enter_invalid_data_for_specific_fields
    fill_in "Opened date", with: "Not a date"
    select "Energy", from: "Market sector"
  end

  def expect_invalid_data_for_specific_fields
    expect(page).to have_css('.elements-error-summary')
    expect(page).to have_css('.elements-error-message')

    expect(page).to have_content("Please fix the following errors")
    expect(page).to have_content("Opened date should be formatted YYYY-MM-DD")
    expect(page).to have_content("Body cannot include invalid Govspeak")
  end

# End: Document specific parts of the test




  # scenario "getting to the new document page" do
  #   visit document_root
  #   click_link "Add another CMA Case"
  #
  #   expect(page.status_code).to eq(200)
  #   expect(page.current_path).to eq(document_root + "/new")
  # end
  #
  # scenario "with valid data" do
  #   visit document_root + "/new"
  #
  #   fill_in "Title", with: "Example CMA Case"
  #   fill_in "Summary", with: "This is the summary of an example CMA case"
  #   fill_in "Body", with: "## Header" + ("\n\nThis is the long body of an example CMA case" * 2)
  #   fill_in "Opened date", with: "2014-01-01"
  #   select "Energy", from: "Market sector"
  #
  #   expect(page).to have_css('div.govspeak-help')
  #   expect(page).to have_content('To add an attachment, please save the draft first.')
  #   expect(save_button_disable_with_message).to eq("Saving...")
  #
  #   click_button "Save as draft"
  #
  #   expected_sent_payload = {
  #     "content_id" => SecureRandom.uuid, # this is stubbed in the setup
  #     "base_path" => "/cma-cases/example-cma-case",
  #     "title" => "Example CMA Case",
  #     "description" => "This is the summary of an example CMA case",
  #     "document_type" => "cma_case",
  #     "schema_name" => "specialist_document",
  #     "publishing_app" => "specialist-publisher",
  #     "rendering_app" => "specialist-frontend",
  #     "locale" => "en",
  #     "phase" => "live",
  #     "details" => {
  #       "body" => [
  #         {
  #           "content_type" => "text/govspeak",
  #           "content" => "## Header\r\n\r\nThis is the long body of an example CMA case\r\n\r\nThis is the long body of an example CMA case"
  #         },
  #         {
  #            "content_type" => "text/html",
  #            "content" => "<h2 id=\"header\">Header</h2>\n\n<p>This is the long body of an example CMA case</p>\n\n<p>This is the long body of an example CMA case</p>\n",
  #         }
  #       ],
  #       "metadata" => {
  #         "opened_date" => "2014-01-01",
  #         "case_type" => "ca98-and-civil-cartels",
  #         "case_state" => "open",
  #         "market_sector" => ["energy"],
  #         "document_type" => "cma_case"
  #       },
  #       "change_history" => [],
  #       "max_cache_time" => 10,
  #       "headers" => [
  #         { "text" => "Header", "level" => 2, "id" => "header" }
  #       ],
  #     },
  #     "routes" => [{ "path" => "/cma-cases/example-cma-case", "type" => "exact" }],
  #     "redirects" => [],
  #     "update_type" => nil,
  #   }
  #
  #   assert_publishing_api_put_content(content_id, expected_sent_payload)
  #
  #   expect(page.status_code).to eq(200)
  #   expect(page).to have_content("Created Example CMA Case")
  #   expect(page).to have_content('Bulk published false')
  # end
  #
  # scenario "with no data" do
  #   visit "/cma-cases/new"
  #
  #   click_button "Save as draft"
  #
  #   expect(page.status_code).to eq(422)
  #
  #   expect(page).to have_css('.elements-error-summary')
  #   expect(page).to have_css('.form-group.elements-error')
  #   expect(page).to have_css('.elements-error-message')
  #
  #   expect(page).to have_content("Please fix the following errors")
  #   expect(page).to have_content("Title can't be blank")
  #   expect(page).to have_content("Summary can't be blank")
  #   expect(page).to have_content("Body can't be blank")
  #   expect(page).to have_content("Market sector can't be blank")
  # end
  #
  # scenario "with invalid data" do
  #   visit "/cma-cases/new"
  #
  #   fill_in "Title", with: "Example CMA Case"
  #   fill_in "Summary", with: "This is the summary of an example CMA case"
  #   fill_in "Body", with: "<script>alert('hello')</script>"
  #   fill_in "Opened date", with: "Not a date"
  #   select "Energy", from: "Market sector"
  #
  #   click_button "Save as draft"
  #
  #   expect(page.status_code).to eq(422)
  #
  #   expect(page).to have_css('.elements-error-summary')
  #   expect(page).to have_css('.elements-error-message')
  #
  #   expect(page).to have_content("Please fix the following errors")
  #   expect(page).to have_content("Opened date should be formatted YYYY-MM-DD")
  #   expect(page).to have_content("Body cannot include invalid Govspeak")
  # end
  #
  # scenario "previewing GovSpeak", js: true do
  #   visit "/cma-cases/new"
  #
  #   fill_in "Body", with: "$CTA some text $CTA"
  #
  #   click_link "Preview"
  #
  #   within(".preview_container") do
  #     expect(page).to have_content("some text")
  #     expect(page).not_to have_content("$CTA")
  #   end
  #
  #   fill_in "Body", with: "[link text](http://www.example.com)"
  #
  #   click_link "Preview"
  #
  #   within(".preview_container") do
  #     expect(page).to have_content("link text")
  #     expect(page).not_to have_content("http://www.example.com")
  #     expect(page).not_to have_content("some text")
  #   end
  # end
end
