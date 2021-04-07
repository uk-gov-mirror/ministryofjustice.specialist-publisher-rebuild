desc "Migrate Service Standard Reports from GDS to CDDO "
task gds_to_cddo_tmp: :environment do
  content_ids = Republisher.content_id_and_locale_pairs_for_document_type("service_standard_report")

  content_ids.each do |content_id, locale|
    RepublishService.new.call(content_id, locale)
  end
end
