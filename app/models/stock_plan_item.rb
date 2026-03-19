class StockPlanItem < ApplicationRecord
  enum :status, { ordered: 0, incoming: 1, received: 2 }, prefix: true

  belongs_to :stock_plan
  belongs_to :supply_forecast
  has_many :sales_interests, dependent: :destroy

  validates :selected_quantity, numericality: { greater_than: 0, only_integer: true }
  validates :supply_forecast_id, uniqueness: true
  validate :selected_quantity_must_fit_forecast

  before_validation :set_initial_status, on: :create
  after_commit :refresh_forecast_selection_state, on: %i[create destroy]

  scope :visible_to_sales, -> { where(status: statuses[:incoming]) }

  def ready_for_incoming?
    supply_forecast.present? &&
      supply_forecast.quantity_available.present? &&
      supply_forecast.estimated_production_date.present? &&
      supply_forecast.estimated_arrival_date.present?
  end

  def sync_with_forecast!
    return unless persisted?
    return if status_incoming? || status_received?
    return unless ready_for_incoming?

    update!(status: :incoming, incoming_at: incoming_at || Time.current)
  end

  def sales_interest_summary_status
    return :none if sales_interests.empty?
    return :customer_waiting if sales_interests.any?(&:status_customer_waiting?)

    :watching
  end

  private

  def set_initial_status
    self.status = ready_for_incoming? ? :incoming : :ordered
    self.incoming_at ||= Time.current if status_incoming?
  end

  def selected_quantity_must_fit_forecast
    return if supply_forecast.blank? || selected_quantity.blank?
    return errors.add(:base, "forecast quantity is not available yet") if supply_forecast.quantity_available.blank?
    return if selected_quantity <= supply_forecast.quantity_available

    errors.add(:selected_quantity, "must be less than or equal to the forecast quantity")
  end

  def refresh_forecast_selection_state
    supply_forecast&.refresh_selection_state!
  end
end
