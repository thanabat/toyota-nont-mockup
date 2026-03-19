class StockOrdersController < ApplicationController
  def index
    @active_tab = params[:tab].presence_in(%w[all ordered incoming]) || "all"
    @all_stock_items = StockPlanItem.includes(:stock_plan, :supply_forecast).sort_by do |item|
      forecast = item.supply_forecast

      [
        item.status_incoming? ? 0 : 1,
        forecast.estimated_arrival_date || Date.new(9999, 12, 31),
        -(item.incoming_at || item.created_at).to_i
      ]
    end
    @stock_items = case @active_tab
    when "ordered"
      @all_stock_items.select(&:status_ordered?)
    when "incoming"
      @all_stock_items.select(&:status_incoming?)
    else
      @all_stock_items
    end
  end

  def show
    @stock_order = StockPlan.includes(stock_plan_items: :supply_forecast).find(params[:id])
  end
end
