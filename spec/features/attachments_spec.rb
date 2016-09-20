require "spec_helper"

RSpec.feature "Working with attachments", type: :feature do
  let(:content_id) { cma_case['content_id'] }
  let(:cma_case) do
    FactoryGirl.create(:cma_case, title: "Example CMA Case", state_history: { "1" => "draft" })
  end

  before do
    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links

    publishing_api_has_content([cma_case], hash_including(document_type: CmaCase.document_type))
    publishing_api_has_item(cma_case)

    log_in_as_editor(:cma_editor)

    visit "/cma-cases/#{content_id}/edit"
  end

  scenario "adding an attachment" do
    click_on "Add attachment"

    fill_in "Title", with: "New cma case image"
    page.attach_file('attachment_file', "spec/support/images/cma_case_image.jpg")

    click_on "Save attachment"

    expect(response.status).to eq(200)
  end

  scenario "editing an attachment" do
  end

  scenario "deleting an attachment" do
  end
end
