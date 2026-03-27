class StockOrdersController < ApplicationController
  def index
    @active_tab = params[:tab].presence_in(%w[all ordered incoming]) || default_stock_tab
    if import_file_flow? && !sales_mode?
      build_import_tracking_workspace
    else
      build_stock_plan_workspace
    end
  end

  def show
    @stock_order = StockPlan.includes(stock_plan_items: :supply_forecast).find(params[:id])
  end

  def check_latest
    active_tab = params[:tab].presence_in(%w[all ordered incoming]) || "all"

    if import_file_flow? && !sales_mode?
      report_type = next_import_report_type
      stage_label = view_context.import_stage_label(report_type)
      sleep 1.1 if Rails.env.development?
      result = ForecastManualSyncService.new(report_type: report_type).call
      session[:import_flow_initialized] = true
      session[:preserve_imported_feed_once] = report_type
      session[:latest_import_report_type] = report_type

      notice = [
        "นำเข้าไฟล์ #{stage_label} ล่าสุดแล้ว",
        "#{result.updated} updated",
        "#{result.inserted} new",
        "#{result.archived} archived",
        "#{result.promoted_to_incoming} moved to incoming"
      ].join(" • ")

      return redirect_to stock_orders_path(tab: active_tab), notice: notice
    end

    ordered_items = StockPlanItem.includes(:supply_forecast).select(&:status_ordered?)
    report_types = ordered_items.filter_map { |item| item.supply_forecast&.source_report_type }.uniq

    if report_types.empty?
      empty_notice = if import_file_flow?
        "นำเข้าไฟล์อัปเดตล่าสุดแล้ว • ตอนนี้ไม่มีรายการที่รออัปเดตเพิ่มเติม"
      else
        "เช็คสถานะล่าสุดแล้ว • ตอนนี้ไม่มีรายการที่รออัปเดตเพิ่มเติม"
      end

      return redirect_to stock_orders_path(tab: active_tab), notice: empty_notice
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

    lead_notice = import_file_flow? ? "นำเข้าไฟล์อัปเดตล่าสุดแล้ว" : "เช็คสถานะล่าสุดแล้ว"
    notice = [
      lead_notice,
      "#{updated} updated",
      "#{inserted} new",
      "#{archived} archived",
      "#{promoted_to_incoming} moved to incoming"
    ].join(" • ")

    redirect_to stock_orders_path(tab: active_tab), notice: notice
  end

  private

  def build_import_tracking_workspace
    @tracking_report_type = latest_import_report_type || "monthly"
    @all_tracking_items = SupplyForecast.active_feed.where(source_report_type: @tracking_report_type).order(:estimated_arrival_date, :source_batch_key, :source_line_no).to_a
    @ordered_count = @all_tracking_items.count { |forecast| !import_tracking_incoming?(forecast) }
    @incoming_count = @all_tracking_items.count { |forecast| import_tracking_incoming?(forecast) }
    @all_count = @all_tracking_items.size
    @stock_items = case @active_tab
    when "ordered"
      @all_tracking_items.reject { |forecast| import_tracking_incoming?(forecast) }
    when "incoming"
      @all_tracking_items.select { |forecast| import_tracking_incoming?(forecast) }
    else
      @all_tracking_items
    end
  end

  def build_stock_plan_workspace
    stock_items_scope = StockPlanItem.includes(:stock_plan, :supply_forecast, :sales_interests)
    @all_stock_items = stock_items_scope.sort_by do |item|
      forecast = item.supply_forecast

      [
        item.status_incoming? ? 0 : 1,
        forecast.estimated_arrival_date || Date.new(9999, 12, 31),
        -(item.incoming_at || item.created_at).to_i
      ]
    end

    if sales_mode?
      @active_tab = "incoming"
      @stock_items = @all_stock_items.select(&:status_incoming?)
      @sales_followed_count = @stock_items.count { |item| item.sales_interests.any? }
      @sales_customer_waiting_count = @stock_items.count do |item|
        item.sales_interests.any?(&:status_prospective_customer?) || item.sales_interests.any?(&:status_customer_reserved?)
      end
    else
      @stock_items = case @active_tab
      when "ordered"
        @all_stock_items.select(&:status_ordered?)
      when "incoming"
        @all_stock_items.select(&:status_incoming?)
      else
        @all_stock_items
      end
    end
  end

  def default_stock_tab
    sales_mode? ? "incoming" : "all"
  end

  def latest_import_report_type
    session[:latest_import_report_type].presence_in(ImportFlowsController::IMPORT_SEQUENCE)
  end

  def next_import_report_type
    return "monthly" if latest_import_report_type.blank?

    sequence = ImportFlowsController::IMPORT_SEQUENCE
    index = sequence.index(latest_import_report_type) || 0
    sequence[(index + 1) % sequence.length]
  end

  def import_tracking_incoming?(forecast)
    forecast.quantity_available.present? &&
      forecast.estimated_production_date.present? &&
      forecast.estimated_arrival_date.present?
  end
end
