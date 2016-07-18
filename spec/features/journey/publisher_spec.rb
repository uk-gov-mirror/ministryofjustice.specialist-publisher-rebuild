require 'spec/spec_helper'

RSpec.feature "publisher journey test" do
  before do
    log_in_as_editor(:gds_editor)
  end

  let(:title) {"My Title #{rand}"}

  let(:document_type) {"RAIB Report"}
  let(:document_route) {"raib-reports"}

  describe 'Publisher Journey', journey: true, js: true do
    it 'should create and preview a draft' do
      visit "http://specialist-publisher-rebuild.dev.gov.uk/manuals"

      expect(page.status_code).to eq(200)

      click_link "Finders"

      expect(page).to have_content("#{document_type}s")

      click_link "#{document_type}s"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("#{document_type}s")

      click_link "Add another #{document_type}"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("New #{document_type}")

      click_button "Save as draft"

      expect(page.status_code).to eq(422)
      expect(page).to have_content("Title can't be blank")
      expect(page).to have_content("Summary can't be blank")
      expect(page).to have_content("Body can't be blank")

      ##################################################################################################################
      # RAIB
      expect(page).to have_content("Date of occurrence can't be blank")
      expect(page).to have_content("Date of occurrence should be formatted YYYY-MM-DD")
      expect(find("div.elements-error-summary")).not_to have_content("Railway")
      expect(find("div.elements-error-summary")).not_to have_content("Report type")
      ##################################################################################################################

      fill_in "Title", with: title
      fill_in "Summary", with: "My Summary"
      fill_in "Body", with: "My Body With A\n\n$CTA\n[Test call to action](https://www.gov.uk/test)\n$CTA"
      fill_in "Date of occurrence", with: "2016-01-01"
      click_link "Preview"
      expect(find("div.preview")).to have_content("Test call to action")
      expect(find("div.preview")).not_to have_content("$CTA")
      expect(find("div.preview")).not_to have_content("n](https")
      click_button "Save as draft"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Preview draft")

      # click_link "Preview draft"
      #
      # expect(page.status_code).to eq(200)
      # expect(page).to have_content("Rail Accident Investigation Branch Report")
      # expect(page).to have_content("Test call to action")
      # expect(page).not_to have_content("$CTA")
      # expect(page).not_to have_content("n](https")

      visit "http://specialist-publisher-rebuild.dev.gov.uk/#{document_route}"
      expect(first("li.document")).to have_content("draft")

      click_link title
      expect(page.status_code).to eq(200)
      click_link "Edit document"
      expect(page).to have_content("Editing #{title}")
      expect(page.status_code).to eq(200)

      ##################################################################################################################
      # RAIB
      select "Heavy rail", from: "Railway type"
      select "Bulletin", from: "Report type"
      ##################################################################################################################

      fill_in "Body", with: "My Altered Body With A\n\n$CTA\n[Test call to action](https://www.gov.uk/test)\n$CTA"

      click_button "Save as draft"
      expect(page).not_to have_content("View on website")
      expect(page).to have_content("Preview draft")
      expect(find("span.label.label-primary")).to have_content("draft")
      expect(all("div.panel-body")[0]).to have_content("Publish")
      expect(all("div.panel-body")[1]).not_to have_content("Unpublish document")

      visit "http://specialist-publisher-rebuild.dev.gov.uk/#{document_route}"
      expect(first("li.document")).to have_content("draft")
    end

    it 'should publish a draft' do
    end

    it 'should edit and republish a report' do
    end

    it 'add attachments?' do
    end

    it 'should unpublish a document' do
    end

    it 'should add documents to Publisher index' do
    end

    it 'should add documents to search list' do
    end
  end
end
