class SalesInterestsController < ApplicationController
  def new
    @stock_plan_item = StockPlanItem.includes(:stock_plan, :supply_forecast, :sales_interests).find(params[:stock_plan_item_id])
    @sales_interest = @stock_plan_item.sales_interests.build(status: :watching)
    @return_tab = params[:tab].presence_in(%w[all ordered incoming]) || "incoming"

    return if @stock_plan_item.status_incoming?

    redirect_to stock_orders_path(tab: @return_tab), alert: "เริ่มติดตามได้เมื่อรายการกลายเป็น Stock กำลังเข้าแล้ว"
  end

  def create
    @stock_plan_item = StockPlanItem.includes(:stock_plan, :supply_forecast, :sales_interests).find(sales_interest_params[:stock_plan_item_id])
    @return_tab = params[:return_tab].presence_in(%w[all ordered incoming]) || "incoming"
    @sales_interest = @stock_plan_item.sales_interests.build(sales_interest_params.except(:stock_plan_item_id))

    unless @stock_plan_item.status_incoming?
      return redirect_to stock_orders_path(tab: @return_tab), alert: "เริ่มติดตามได้เมื่อรายการกลายเป็น Stock กำลังเข้าแล้ว"
    end

    if @sales_interest.save
      redirect_to stock_orders_path(tab: @return_tab), notice: "บันทึกการติดตามของฝ่ายขายแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def sales_interest_params
    params.require(:sales_interest).permit(:stock_plan_item_id, :sales_name, :branch_name, :status, :note)
  end
end
