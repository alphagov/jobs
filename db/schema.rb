# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110914151714) do

  create_table "jobs", :force => true do |t|
    t.string   "vacancy_id"
    t.string   "vacancy_title"
    t.string   "soc_code"
    t.string   "wage"
    t.string   "wage_qualifier"
    t.string   "wage_display_text"
    t.integer  "wage_sort_order_id"
    t.string   "currency"
    t.boolean  "is_national"
    t.boolean  "is_regional"
    t.integer  "hours"
    t.string   "hours_qualifier"
    t.string   "hours_display_text"
    t.decimal  "longitude",             :precision => 15, :scale => 10
    t.decimal  "latitude",              :precision => 15, :scale => 10
    t.string   "location_name"
    t.string   "location_display_name"
    t.boolean  "is_permanent"
    t.date     "received_on"
    t.datetime "first_import_at"
    t.datetime "most_recent_import_at"
    t.string   "employer_name"
    t.text     "eligability_criteria"
    t.text     "vacancy_description"
    t.text     "how_to_apply"
  end

  add_index "jobs", ["vacancy_id"], :name => "index_jobs_on_vacancy_id", :unique => true

end
