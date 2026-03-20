class SalesInterest < ApplicationRecord
  enum :status, { watching: 0, prospective_customer: 1, customer_reserved: 2 }, prefix: true

  belongs_to :stock_plan_item

  validates :sales_name, :branch_name, :status, presence: true
end
