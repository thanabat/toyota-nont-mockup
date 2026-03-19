class StockOrdersController < ApplicationController
  def index
    @stock_orders = StockPlan.includes(stock_plan_items: :supply_forecast).order(created_at: :desc)
  end

  def show
    @stock_order = StockPlan.includes(stock_plan_items: :supply_forecast).find(params[:id])
  end
end
