class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :vacancy_id
      t.string :vacancy_title
      t.string :soc_code
      t.string :wage
      t.string :wage_qualifier
      t.string :wage_display_text
      t.integer :wage_sort_order_id
      t.string :currency
      t.boolean :is_national
      t.boolean :is_regional
      t.integer :hours
      t.string :hours_qualifier
      t.string :hours_display_text
      t.decimal :longitude, :precision => 15, :scale => 10
      t.decimal :latitude, :precision => 15, :scale => 10
      t.string :location_name
      t.string :location_display_name
      t.boolean :is_permanent
      t.date :received_on

      t.datetime :first_import_at
      t.datetime :most_recent_import_at
    end
    add_index :jobs, :vacancy_id, :unique => true
  end
end
