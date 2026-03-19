class ForecastSyncRun < ApplicationRecord
  enum :trigger_mode, { manual: 0, automatic: 1 }, prefix: true
  enum :source_report_type, { daily: 0, weekly: 1, monthly: 2 }, prefix: true
  enum :status, { running: 0, completed: 1, failed: 2 }, prefix: true

  has_many :supply_forecasts, dependent: :restrict_with_exception

  validates :started_at, presence: true
  validates :records_processed, :records_inserted, :records_updated, :records_archived,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
