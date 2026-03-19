class SalesInterest < ApplicationRecord
  enum :status, { watching: 0, customer_waiting: 1 }, prefix: true

  belongs_to :stock_plan_item

  validates :sales_name, :branch_name, :status, presence: true
end
