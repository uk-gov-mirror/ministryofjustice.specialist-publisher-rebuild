class AaibReport < Document
  attr_accessor :date_of_occurrence
  validates :date_of_occurrence, presence: true, date: true, unless: ->(report) {
    report.report_type == "safety-study" && report.date_of_occurrence.blank?
  }

  FORMAT_SPECIFIC_FIELDS = %i(
    date_of_occurrence
    date_of_occurrence_dateday
    date_of_occurrence_datemonth
    date_of_occurrence_dateyear
    aircraft_category
    report_type
    location
    aircraft_type
    registration
  )

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def date_of_occurrence
    @date_of_occurrence = "#{date_of_occurrence_dateyear}-#{date_of_occurrence_datemonth}-#{date_of_occurrence_dateday}"
  end

  def self.title
    "AAIB Report"
  end
end
