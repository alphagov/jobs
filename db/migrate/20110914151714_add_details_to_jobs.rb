class AddDetailsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :employer_name, :string
    add_column :jobs, :eligability_criteria, :text
    add_column :jobs, :vacancy_description, :text
    add_column :jobs, :messages, :text
    add_column :jobs, :how_to_apply, :text
  end
end
