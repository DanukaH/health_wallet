class Import
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUSES = %w[pending processing completed failed].freeze

  field :filename, type: String
  field :content, type: String
  field :status, type: String, default: "pending"
  field :error_message, type: String
  field :patients_imported, type: Integer, default: 0
  field :assessments_imported, type: Integer, default: 0
  field :observations_imported, type: Integer, default: 0
  field :observations_skipped, type: Integer, default: 0

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order_by(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end
end
