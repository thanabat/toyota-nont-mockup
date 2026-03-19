class IncomingStocksController < ApplicationController
  def index
    redirect_to stock_orders_path(tab: :incoming)
  end
end
