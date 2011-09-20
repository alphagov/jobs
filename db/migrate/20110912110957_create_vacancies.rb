class CreateVacancies < ActiveRecord::Migration
  def change
    create_table :vacancies do |t|
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

      t.date :first_import_on
      t.date :most_recent_import_on

      t.string :employer_name
      t.text :eligability_criteria
      t.text :vacancy_description
      t.text :how_to_apply
    end
    add_index :vacancies, :vacancy_id, :unique => true
  end
end
