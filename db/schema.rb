# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_19_113000) do
  create_table "forecast_sync_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "initiated_by"
    t.integer "records_archived", default: 0, null: false
    t.integer "records_inserted", default: 0, null: false
    t.integer "records_processed", default: 0, null: false
    t.integer "records_updated", default: 0, null: false
    t.integer "source_report_type", default: 0, null: false
    t.datetime "started_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "trigger_mode", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_plan_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.integer "selected_quantity", default: 1, null: false
    t.integer "stock_plan_id", null: false
    t.integer "supply_forecast_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_plan_id"], name: "index_stock_plan_items_on_stock_plan_id"
    t.index ["supply_forecast_id"], name: "index_stock_plan_items_on_supply_forecast_id", unique: true
    t.check_constraint "selected_quantity > 0", name: "stock_plan_items_selected_quantity_positive"
  end

  create_table "stock_plans", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.text "note"
    t.string "plan_no", null: false
    t.integer "plan_type", default: 0, null: false
    t.string "requested_by", null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["plan_no"], name: "index_stock_plans_on_plan_no", unique: true
    t.index ["status"], name: "index_stock_plans_on_status"
  end

  create_table "supply_forecasts", force: :cascade do |t|
    t.datetime "change_detected_at"
    t.string "color_code"
    t.string "color_name"
    t.datetime "created_at", null: false
    t.date "estimated_arrival_date"
    t.date "estimated_production_date"
    t.integer "forecast_sync_run_id", null: false
    t.string "grade"
    t.datetime "last_synced_at", null: false
    t.string "model_code", null: false
    t.string "model_label"
    t.integer "quantity_available", default: 0, null: false
    t.datetime "selected_at"
    t.date "source_generated_on"
    t.string "source_key", null: false
    t.integer "source_report_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["estimated_arrival_date"], name: "index_supply_forecasts_on_estimated_arrival_date"
    t.index ["forecast_sync_run_id"], name: "index_supply_forecasts_on_forecast_sync_run_id"
    t.index ["source_key"], name: "index_supply_forecasts_on_source_key", unique: true
    t.index ["status"], name: "index_supply_forecasts_on_status"
    t.check_constraint "quantity_available >= 0", name: "supply_forecasts_quantity_available_non_negative"
  end

  add_foreign_key "stock_plan_items", "stock_plans"
  add_foreign_key "stock_plan_items", "supply_forecasts"
  add_foreign_key "supply_forecasts", "forecast_sync_runs"
end
