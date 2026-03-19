class ForecastStockOrdersController < ApplicationController
  before_action :load_selected_forecasts
  before_action :ensure_forecasts_selected

  def new
    @draft_stock_orders = draft_stock_orders
  end

  def create
    @draft_stock_orders = draft_stock_orders
    @stock_order = selected_stock_order
    @stock_order_items = build_stock_order_items(@stock_order)

    if @stock_order_items.all?(&:valid?)
      ActiveRecord::Base.transaction do
        @stock_order.save! if @stock_order.new_record?
        @stock_order_items.each(&:save!)
      end

      redirect_to stock_order_path(@stock_order), notice: "สั่งเข้า Stock แล้ว #{@stock_order_items.size} รายการ"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_selected_forecasts
    @selected_forecast_ids = raw_selected_forecast_ids
    @selected_forecasts = SupplyForecast.includes(stock_plan_item: :stock_plan)
      .where(id: @selected_forecast_ids)
      .order(:source_batch_key, :source_line_no)
    @report_type = params[:report_type].presence || batch_params[:report_type].presence || @selected_forecasts.first&.source_report_type || "daily"
  end

  def ensure_forecasts_selected
    return if @selected_forecasts.any?

    redirect_to forecasts_path(report_type: @report_type), alert: "กรุณาเลือก forecast อย่างน้อย 1 รายการก่อนสั่งเข้า Stock"
  end

  def draft_stock_orders
    StockPlan.status_draft.order(created_at: :desc)
  end

  def selected_stock_order
    if batch_params[:stock_order_id] == "new"
      StockPlan.new(
        plan_no: next_plan_number,
        title: batch_params[:new_stock_order_title].presence || default_stock_order_title,
        requested_by: "allocation.team",
        plan_type: :target_driven,
        status: :draft,
        note: "สร้างจาก forecast #{@selected_forecasts.size} รายการ"
      )
    else
      StockPlan.find(batch_params[:stock_order_id])
    end
  end

  def build_stock_order_items(stock_order)
    item_params_by_forecast = batch_params.fetch(:items, {}).to_h.stringify_keys

    @selected_forecasts.map do |forecast|
      attrs = item_params_by_forecast.fetch(forecast.id.to_s, {})
      StockPlanItem.new(
        stock_plan: stock_order,
        supply_forecast: forecast,
        selected_quantity: attrs["selected_quantity"],
        note: attrs["note"]
      )
    end
  end

  def raw_selected_forecast_ids
    ids = params[:forecast_ids] || batch_params[:forecast_ids]
    Array(ids).map(&:presence).compact
  end

  def next_plan_number
    latest_number = StockPlan.pluck(:plan_no).filter_map do |plan_no|
      match = plan_no.to_s.match(/SP-(\d{8})-(\d{3})\z/)
      match[2].to_i if match && match[1] == Date.current.strftime("%Y%m%d")
    end.max.to_i

    "SP-#{Date.current.strftime('%Y%m%d')}-#{format('%03d', latest_number + 1)}"
  end

  def default_stock_order_title
    first_label = @selected_forecasts.first&.model_label || @selected_forecasts.first&.model_code
    "สั่งเข้า Stock #{first_label} และอีก #{@selected_forecasts.size - 1} รายการ"
  end

  def batch_params
    raw_params = params[:stock_order_batch].presence || ActionController::Parameters.new
    raw_params.permit(:stock_order_id, :new_stock_order_title, :report_type, forecast_ids: [], items: %i[selected_quantity note])
  end
end
