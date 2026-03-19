class ForecastManualSyncService
  REPORT_TYPES = %w[daily weekly monthly].freeze

  NEW_LINE_LIBRARY = {
    "daily" => [
      { model_code: "ATIV-HEV", model_label: "Yaris Ativ HEV Premium", grade: "Premium", color_code: "2SZ", color_name: "Dark Turquoise" },
      { model_code: "RAIZE", model_label: "Raize Turbo", grade: "Turbo", color_code: "W25", color_name: "White Pearl" },
      { model_code: "VIOS", model_label: "Vios Smart Entry", grade: "Smart Entry", color_code: "R89", color_name: "Red Mica Metallic" }
    ],
    "weekly" => [
      { model_code: "HILUX-ROCCO", model_label: "Hilux Revo Rocco 4x4", grade: "Rocco", color_code: "B20", color_name: "Attitude Black Mica" },
      { model_code: "FORTUNER-LEGENDER", model_label: "Fortuner Legender", grade: "Legender", color_code: "W29", color_name: "Platinum White Pearl" },
      { model_code: "INNOVA-ZENIX-HV", model_label: "Innova Zenix Hybrid", grade: "Hybrid Smart", color_code: "G58", color_name: "Grey Metallic" }
    ],
    "monthly" => [
      { model_code: "CAMRY-HEV", model_label: "Camry HEV Premium Luxury", grade: "Premium Luxury", color_code: "P19", color_name: "Precious Metal" },
      { model_code: "BZ4X", model_label: "bZ4X AWD", grade: "AWD", color_code: "B21", color_name: "Black / Precious Metal" },
      { model_code: "ALPHARD", model_label: "Alphard Executive Lounge", grade: "Executive Lounge", color_code: "P25", color_name: "Precious Leo Black" }
    ]
  }.freeze

  Result = Struct.new(:sync_run, :inserted, :updated, :archived, keyword_init: true)

  def initialize(report_type:)
    @report_type = report_type.to_s
  end

  def call
    raise ArgumentError, "unsupported report type" unless REPORT_TYPES.include?(@report_type)

    forecasts = SupplyForecast.active_feed.where(source_report_type: @report_type).order(:source_batch_key, :source_line_no)
    return Result.new(sync_run: nil, inserted: 0, updated: 0, archived: 0) if forecasts.empty?

    started_at = Time.current
    sync_sequence = next_sequence
    sync_run = ForecastSyncRun.create!(
      started_at: started_at,
      trigger_mode: :manual,
      source_report_type: @report_type,
      status: :running,
      initiated_by: "allocation.team"
    )

    inserted = 0
    updated = 0
    archived = 0
    batch_key = batch_key_for(sync_sequence)
    incoming_rows = build_incoming_rows(forecasts, batch_key, sync_sequence)
    incoming_keys = incoming_rows.map { |row| row[:source_key] }

    SupplyForecast.transaction do
      incoming_rows.each_with_index do |attributes, index|
        payload = attributes.merge(
          source_batch_key: batch_key,
          source_line_no: index + 1,
          source_report_type: @report_type,
          source_generated_on: Date.current
        )

        forecast = SupplyForecast.find_by(source_key: payload[:source_key])

        if forecast.present?
          forecast.apply_sync!(payload, forecast_sync_run: sync_run)
          updated += 1
        else
          SupplyForecast.create!(
            payload.merge(
              forecast_sync_run: sync_run,
              quantity_available: payload[:quantity_available],
              last_synced_at: Time.current,
              first_seen_at: Time.current,
              last_sync_change_kind: :inserted,
              status: :available
            )
          )
          inserted += 1
        end
      end

      forecasts.each do |forecast|
        next if incoming_keys.include?(forecast.source_key)

        forecast.archive_from_sync!(forecast_sync_run: sync_run)
        archived += 1
      end

      sync_run.update!(
        completed_at: Time.current,
        status: :completed,
        records_processed: incoming_rows.size + archived,
        records_inserted: inserted,
        records_updated: updated,
        records_archived: archived
      )
    end

    Result.new(sync_run: sync_run, inserted: inserted, updated: updated, archived: archived)
  rescue StandardError => error
    sync_run&.update!(
      completed_at: Time.current,
      status: :failed,
      error_message: error.message
    )
    raise
  end

  private

  def build_incoming_rows(forecasts, batch_key, sync_sequence)
    kept_rows = forecasts.each_with_index.filter_map do |forecast, index|
      next if removable?(forecast, index, sync_sequence)

      synced_attributes_for(forecast, index, batch_key, sync_sequence)
    end

    fresh_rows = fresh_line_templates(sync_sequence).map.with_index do |template, index|
      build_new_row(template, batch_key, sync_sequence, kept_rows.size + index + 1)
    end

    (kept_rows + fresh_rows).sort_by { |row| [row[:estimated_arrival_date] || Date.current, row[:model_label].to_s] }
  end

  def synced_attributes_for(forecast, index, batch_key, sync_sequence)
    payload = {
      source_key: forecast.source_key,
      source_batch_key: batch_key,
      source_line_no: index + 1,
      model_code: forecast.model_code,
      model_label: forecast.model_label,
      grade: forecast.grade,
      color_code: forecast.color_code,
      color_name: forecast.color_name
    }

    apply_report_completeness!(
      payload,
      existing_forecast: forecast,
      index: index,
      sync_sequence: sync_sequence
    )
  end

  def build_new_row(template, batch_key, sync_sequence, line_no)
    payload = {
      source_key: "#{batch_key}-L#{line_no}-N#{sync_sequence}",
      source_batch_key: batch_key,
      source_line_no: line_no,
      model_code: template[:model_code],
      model_label: template[:model_label],
      grade: template[:grade],
      color_code: template[:color_code],
      color_name: template[:color_name]
    }

    apply_report_completeness!(payload, existing_forecast: nil, index: line_no, sync_sequence: sync_sequence)
  end

  def fresh_line_templates(sync_sequence)
    NEW_LINE_LIBRARY.fetch(@report_type).rotate(sync_sequence % 3).first(2)
  end

  def removable?(forecast, index, sync_sequence)
    forecast.stock_plan_item.blank? && (index + sync_sequence).modulo(5).zero?
  end

  def apply_report_completeness!(payload, existing_forecast:, index:, sync_sequence:)
    quantity_delta = ((sync_sequence + index) % 3) - 1
    production_shift = (sync_sequence + index) % 3
    arrival_shift = ((sync_sequence + index) % 4) + 1
    base_quantity = existing_forecast&.quantity_available || 2 + ((sync_sequence + index) % 4)
    base_production_date = existing_forecast&.estimated_production_date || Date.current + (sync_sequence + index).days
    base_arrival_date = existing_forecast&.estimated_arrival_date || Date.current + (sync_sequence + index + 6).days

    case @report_type
    when "daily"
      payload[:grade] = nil if (sync_sequence + index).odd?
      payload[:quantity_available] = nil
      payload[:estimated_production_date] = nil
      payload[:estimated_arrival_date] = nil
    when "weekly"
      payload[:quantity_available] = [base_quantity + quantity_delta, 1].max
      payload[:estimated_production_date] = base_production_date + production_shift.days
      payload[:estimated_arrival_date] = nil
    when "monthly"
      payload[:quantity_available] = [base_quantity + quantity_delta, 1].max
      payload[:estimated_production_date] = base_production_date + production_shift.days
      payload[:estimated_arrival_date] = base_arrival_date + arrival_shift.days
    end

    payload
  end

  def batch_key_for(sequence)
    "FC-#{@report_type.upcase}-#{Date.current.strftime('%Y%m%d')}-#{format('%03d', sequence)}"
  end

  def next_sequence
    [latest_sync_run_sequence, latest_batch_sequence].max + 1
  end

  def latest_sync_run_sequence
    ForecastSyncRun.where(source_report_type: @report_type).count
  end

  def latest_batch_sequence
    SupplyForecast.where(source_report_type: @report_type).pluck(:source_batch_key).filter_map do |batch_key|
      match = batch_key.to_s.match(/-(\d{3})\z/)
      match[1].to_i if match
    end.max.to_i
  end
end
