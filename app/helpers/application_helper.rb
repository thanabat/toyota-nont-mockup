module ApplicationHelper
  FORECAST_COLOR_STYLE_BY_CODE = {
    "089" => "background-color: #f4f1eb;",
    "1L0" => "background-color: #1c1c1c;",
    "1K3" => "background-color: #8b9198;",
    "040" => "background-color: #f8f8f6;",
    "1D6" => "background-color: #a9afb4;",
    "218" => "background-color: #6f5a4d;",
    "W09" => "background-color: #fcfbf7;",
    "3U5" => "background-color: #9c2030;",
    "1J9" => "background-color: #b8b8b4;",
    "8W7" => "background-color: #575d63;",
    "2SZ" => "background-color: #3d7f80;",
    "W25" => "background-color: #fcfbf7;",
    "R89" => "background-color: #a32031;",
    "B20" => "background-color: #1c1c1c;",
    "W29" => "background-color: #f4f1eb;",
    "G58" => "background-color: #8f979d;",
    "P19" => "background-color: #b7b8ba;",
    "B21" => "background: linear-gradient(135deg, #101010 0 48%, #b7b8ba 48% 100%);",
    "P25" => "background-color: #202124;"
  }.freeze

  def forecast_color_swatch(forecast)
    label = [ forecast.color_name.presence, forecast.color_code.presence ].compact.join(" • ").presence || "ไม่ระบุสี"
    style = forecast_color_style_for(forecast)

    content_tag(
      :span,
      "",
      class: "inline-flex h-10 w-10 rounded-xl border border-stone-300 shadow-inner",
      style: style,
      title: label,
      aria: { label: label }
    )
  end

  def sidebar_link_classes(path)
    base_classes = "group flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition"
    active_classes = "app-nav-link--active"
    inactive_classes = "app-nav-link--inactive"

    active = if path == root_path
      request.path == path
    else
      request.path == path || request.path.start_with?("#{path}/")
    end

    [ base_classes, active ? active_classes : inactive_classes ].join(" ")
  end

  def sidebar_icon(name)
    paths = case name
    when :home
      '<path d="M3 9.5 10 4l7 5.5V17a1 1 0 0 1-1 1h-4v-5H8v5H4a1 1 0 0 1-1-1V9.5Z" />'
    when :forecast
      '<path d="M4 4h12v3H4zM4 9h12v7H4zM6 11h3v3H6zM11 11h3v1h-3zM11 13h3v1h-3z" />'
    when :orders
      '<path d="M5 4h8l3 3v9H5V4Zm8 1.5V8h2.5" /><path d="M7 11h6M7 13.5h6" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round" />'
    when :incoming
      '<path d="M10 3v8" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round" /><path d="m6.5 8.5 3.5 3.5 3.5-3.5" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round" stroke-linejoin="round" /><path d="M4 15h12" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round" />'
    else
      '<circle cx="10" cy="10" r="6" />'
    end

    content_tag(:svg, paths.html_safe, viewBox: "0 0 20 20", fill: "currentColor", class: "h-4 w-4")
  end

  def incoming_stock_reference(item)
    "STK-#{item.id.to_s.rjust(4, '0')}"
  end

  def incoming_stock_location(item)
    note = item.note.to_s.downcase

    return "โชว์รูมบางบัวทอง" if note.include?("bang bua thong") || note.include?("บางบัวทอง")
    return "โชว์รูมปากเกร็ด" if note.include?("ปากเกร็ด") || note.include?("pak kret")

    case item.supply_forecast.model_code.to_s
    when /HILUX|REVO/
      "ลานพักรถรัตนาธิเบศร์"
    when /FORTUNER|CAMRY|YARIS-CROSS/
      "โชว์รูมบางบัวทอง"
    when /YARIS-ATIV|COROLLA/
      "ศูนย์กระจายนนทบุรี"
    else
      "โชว์รูมรัตนาธิเบศร์"
    end
  end

  def incoming_stock_arrival_label(item)
    arrival_date = item.supply_forecast.estimated_arrival_date
    return "-" if arrival_date.blank?

    days_remaining = (arrival_date - Date.current).to_i

    if days_remaining.positive?
      "อีก #{days_remaining} วัน"
    elsif days_remaining.zero?
      "ถึงวันนี้"
    else
      "ช้า #{days_remaining.abs} วัน"
    end
  end

  private

  def forecast_color_style_for(forecast)
    code = forecast.color_code.to_s.upcase
    return FORECAST_COLOR_STYLE_BY_CODE[code] if FORECAST_COLOR_STYLE_BY_CODE.key?(code)

    color_name = forecast.color_name.to_s.downcase
    return "background-color: #1c1c1c;" if color_name.include?("black")
    return "background-color: #f8f8f6;" if color_name.include?("white")
    return "background-color: #a32031;" if color_name.include?("red")
    return "background-color: #6f5a4d;" if color_name.include?("brown")
    return "background-color: #8b9198;" if color_name.include?("metal") || color_name.include?("steel") || color_name.include?("grey")

    "background: repeating-linear-gradient(135deg, #d6d3d1, #d6d3d1 8px, #f5f5f4 8px, #f5f5f4 16px);"
  end
end
