class StockPlan < ApplicationRecord
  enum :plan_type, { target_driven: 0, demand_driven: 1 }, prefix: true
  enum :status, { draft: 0, confirmed: 1, closed: 2 }, prefix: true

  has_many :stock_plan_items, dependent: :destroy
  has_many :supply_forecasts, through: :stock_plan_items

  validates :plan_no, :requested_by, presence: true
  validates :plan_no, uniqueness: true
end
