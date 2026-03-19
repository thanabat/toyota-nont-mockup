class SupplyForecast < ApplicationRecord
  SYNC_TRACKED_ATTRIBUTES = %w[
    source_batch_key
    source_line_no
    source_report_type
    model_code
    model_label
    grade
    color_code
    color_name
    quantity_available
    estimated_production_date
    estimated_arrival_date
    source_generated_on
  ].freeze

  enum :source_report_type, { daily: 0, weekly: 1, monthly: 2 }, prefix: true
  enum :status, { available: 0, selected: 1, changed_after_selection: 2, cancelled: 3 }, prefix: true
  enum :last_sync_change_kind, { unchanged: 0, updated: 1, inserted: 2, archived: 3 }, prefix: true

  belongs_to :forecast_sync_run
  has_one :stock_plan_item, dependent: :restrict_with_exception

  scope :active_feed, -> { where.not(status: statuses[:cancelled]) }

  before_validation :set_first_seen_at, on: :create

  validates :source_key, :source_batch_key, :model_code, :last_synced_at, :first_seen_at, presence: true
  validates :source_key, uniqueness: true
  validates :source_line_no, numericality: { greater_than: 0, only_integer: true }
  validates :quantity_available, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  def apply_sync!(attributes, forecast_sync_run:)
    attributes = attributes.stringify_keys
    tracked_changes = sync_tracked_changes?(attributes)

    assign_attributes(attributes.slice(*SYNC_TRACKED_ATTRIBUTES))
    self.forecast_sync_run = forecast_sync_run
    self.last_synced_at = Time.current
    self.last_sync_change_kind = tracked_changes ? :updated : :unchanged

    if stock_plan_item.present?
      self.status = tracked_changes ? :changed_after_selection : :selected
      self.change_detected_at = tracked_changes ? Time.current : nil
    else
      self.status = :available
      self.change_detected_at = nil
    end

    save!
    stock_plan_item&.sync_with_forecast!
  end

  def archive_from_sync!(forecast_sync_run:)
    return if stock_plan_item.present?

    update!(
      forecast_sync_run: forecast_sync_run,
      last_synced_at: Time.current,
      status: :cancelled,
      last_sync_change_kind: :archived,
      change_detected_at: nil
    )
  end

  def refresh_selection_state!
    if stock_plan_item.present?
      update!(status: :selected, selected_at: stock_plan_item.created_at || Time.current, change_detected_at: nil)
    else
      update!(status: :available, selected_at: nil, change_detected_at: nil)
    end
  end

  private

  def sync_tracked_changes?(attributes)
    SYNC_TRACKED_ATTRIBUTES.any? do |attribute|
      next false unless attributes.key?(attribute)

      public_send(attribute).to_s != attributes[attribute].to_s
    end
  end

  def set_first_seen_at
    self.first_seen_at ||= Time.current
  end
end
