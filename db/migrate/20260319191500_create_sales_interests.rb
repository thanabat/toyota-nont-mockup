class CreateSalesInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_interests do |t|
      t.references :stock_plan_item, null: false, foreign_key: true
      t.string :sales_name, null: false
      t.string :branch_name, null: false
      t.integer :status, null: false, default: 0
      t.text :note

      t.timestamps
    end

    add_index :sales_interests, :status
  end
end
