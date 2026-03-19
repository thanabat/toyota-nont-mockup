class StockPlanItem < ApplicationRecord
  belongs_to :stock_plan
  belongs_to :supply_forecast

  validates :selected_quantity, numericality: { greater_than: 0, only_integer: true }
  validates :supply_forecast_id, uniqueness: true
  validate :selected_quantity_must_fit_forecast

  after_commit :refresh_forecast_selection_state, on: %i[create update destroy]

  private

  def selected_quantity_must_fit_forecast
    return if supply_forecast.blank? || selected_quantity.blank?
    return if selected_quantity <= supply_forecast.quantity_available

    errors.add(:selected_quantity, "must be less than or equal to the forecast quantity")
  end

  def refresh_forecast_selection_state
    supply_forecast&.refresh_selection_state!
  end
end
