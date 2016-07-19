require 'spec/spec_helper'

RSpec.feature "adding a section to a manual" do
  before do
    log_in_as(:cma_writer)
  end

  let(:title) {"My Title #{rand}"}

  let(:document_type) {"CMA Case"}
  let(:document_route) {"cma-cases"}

  describe 'My behaviour', journey: true, js: true do
    it 'should create and preview and edit a draft' do
      visit "http://specialist-publisher-rebuild.dev.gov.uk/manuals"

      expect(page).to have_content("#{document_type}s")

      visit "http://specialist-publisher-rebuild.dev.gov.uk/#{document_route}"

      expect(page.status_code).to eq(200)

      expect(page).to have_content("#{document_type}s")

      expect(page).to have_content("Add another")

      click_link "Add another #{document_type}"

      expect(page.status_code).to eq(200)

      expect(page).to have_content("New #{document_type}")

      fill_in "Title", with: title
      fill_in "Summary", with: "My Summary"
      fill_in "Body", with: "My Body With A\n\n$CTA\n[Test call to action](https://www.gov.uk/test)\n$CTA"

      format_specific_entry

      click_button "Save as draft"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Preview draft")
      expect(page).not_to have_content("View on website")
      expect(page).to have_content("Preview draft")
      expect(find("span.label.label-primary")).to have_content("draft")
      expect(all("div.panel-body")[0]).not_to have_content("Publish")
      expect(all("div.panel-body")[1]).not_to have_content("Unpublish document")

      visit "http://specialist-publisher-rebuild.dev.gov.uk/#{document_route}"
      expect(first("li.document")).to have_content("draft")

      click_link title

      expect(page).to have_content("Edit document")

      click_link "Edit document"

      expect(page).to have_content("Editing #{title}")
      fill_in "Body", with: "My Altered Body With A\n\n$CTA\n[Test call to action](https://www.gov.uk/test)\n$CTA"

      click_button "Save as draft"

      expect(page).not_to have_content("View on website")
      expect(page).to have_content("Preview draft")
      expect(find("span.label.label-primary")).to have_content("draft")
      expect(all("div.panel-body")[0]).not_to have_content("Publish")
      expect(all("div.panel-body")[1]).not_to have_content("Unpublish")

      visit "http://specialist-publisher-rebuild.dev.gov.uk/#{document_route}"

      expect(first("li.document")).to have_content("draft")
    end

    def format_specific_entry
      if document_type == "RAIB Report"
        fill_in "Date of occurrence", with: "2016-01-01"
      elsif document_type == "CMA Case"
        select "Aerospace", from: "Market sector"
      end
    end
  end
end
