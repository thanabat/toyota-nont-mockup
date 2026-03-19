class StockOrdersController < ApplicationController
  def index
    @active_tab = params[:tab].presence_in(%w[all ordered incoming]) || default_stock_tab
    @all_stock_items = StockPlanItem.includes(:stock_plan, :supply_forecast, :sales_interests).sort_by do |item|
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

  def check_latest
    active_tab = params[:tab].presence_in(%w[all ordered incoming]) || "all"
    ordered_items = StockPlanItem.includes(:supply_forecast).select(&:status_ordered?)
    report_types = ordered_items.filter_map { |item| item.supply_forecast&.source_report_type }.uniq

    if report_types.empty?
      return redirect_to stock_orders_path(tab: active_tab), notice: "เช็คสถานะล่าสุดแล้ว • ตอนนี้ไม่มีรายการที่รออัปเดตเพิ่มเติม"
    end

    sleep 1.1 if Rails.env.development?

    inserted = 0
    updated = 0
    archived = 0
    promoted_to_incoming = 0

    report_types.each do |report_type|
      result = ForecastManualSyncService.new(report_type: report_type).call
      inserted += result.inserted
      updated += result.updated
      archived += result.archived
      promoted_to_incoming += result.promoted_to_incoming
    end

    notice = [
      "เช็คสถานะล่าสุดแล้ว",
      "#{updated} updated",
      "#{inserted} new",
      "#{archived} archived",
      "#{promoted_to_incoming} moved to incoming"
    ].join(" • ")

    redirect_to stock_orders_path(tab: active_tab), notice: notice
  end

  private

  def default_stock_tab
    sales_mode? ? "incoming" : "all"
  end
end
