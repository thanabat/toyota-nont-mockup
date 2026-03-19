class IncomingStocksController < ApplicationController
  def index
    @incoming_items = StockPlanItem.visible_to_sales.includes(:stock_plan, :supply_forecast)
                                   .sort_by do |item|
      [
        item.supply_forecast.estimated_arrival_date || Date.new(9999, 12, 31),
        -(item.incoming_at || item.created_at).to_i
      ]
    end
  end
end
