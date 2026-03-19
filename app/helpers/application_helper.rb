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
