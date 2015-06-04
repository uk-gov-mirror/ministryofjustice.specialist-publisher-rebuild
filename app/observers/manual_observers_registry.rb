require "gds_api/publishing_api"
require "gds_api/organisations"
require "manual_publishing_api_exporter"
require "manual_section_publishing_api_exporter"
require "publishing_api_withdrawer"
require "rummager_indexer"
require "formatters/manual_indexable_formatter"
require "formatters/manual_section_indexable_formatter"

class ManualObserversRegistry
  def publication
    # The order here is important. For example content exporting
    # should happen before publishing to search.
    [
      publication_logger,
      panopticon_exporter,
      publishing_api_exporter,
      rummager_exporter,
    ]
  end

  def republication
    [
      panopticon_exporter,
      publishing_api_exporter,
      rummager_exporter,
    ]
  end

  def creation
    []
  end

  def withdrawal
    [
      publishing_api_withdrawer,
      rummager_withdrawer,
      panopticon_exporter,
    ]
  end

private
  def publication_logger
    ->(manual) {
      manual.documents.each do |doc|
        PublicationLog.create!(
          title: doc.title,
          slug: doc.slug,
          version_number: doc.version_number,
          change_note: doc.change_note,
        )
      end
    }
  end

  def rummager_exporter
    ->(manual) {
      indexer = RummagerIndexer.new

      indexer.add(
        ManualIndexableFormatter.new(manual)
      )

      manual.documents.each do |section|
        indexer.add(
          ManualSectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end
    }
  end

  def rummager_withdrawer
    ->(manual) {
      indexer = RummagerIndexer.new

      indexer.delete(
        ManualIndexableFormatter.new(manual)
      )

      manual.documents.each do |section|
        indexer.delete(
          ManualSectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end
    }
  end

  def panopticon_exporter
    SpecialistPublisherWiring.get(:manual_panopticon_registerer)
  end

  def publishing_api_exporter
    ->(manual) {
      manual_renderer = SpecialistPublisherWiring.get(:manual_renderer)
      ManualPublishingAPIExporter.new(
        publishing_api,
        organisations_api,
        manual_renderer,
        PublicationLog,
        manual
      ).call

      document_renderer = SpecialistPublisherWiring.get(:manual_document_renderer)
      manual.documents.each do |document|
        ManualSectionPublishingAPIExporter.new(
          publishing_api,
          organisations_api,
          document_renderer,
          manual,
          document
        ).call
      end
    }
  end

  def publishing_api_withdrawer
    ->(manual) {
      PublishingAPIWithdrawer.new(
        publishing_api: publishing_api,
        entity: manual,
      ).call

      manual.documents.each do |document|
        PublishingAPIWithdrawer.new(
          publishing_api: publishing_api,
          entity: document,
        ).call
      end
    }
  end

  def publishing_api
    GdsApi::PublishingApi.new(Plek.new.find("publishing-api"))
  end

  def organisations_api
    GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end
end
