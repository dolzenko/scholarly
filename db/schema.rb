# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100601142201) do

  create_table "git_hub_code_search_results", :force => true do |t|
    t.text     "result"
    t.integer  "start_index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uri"
  end

  create_table "google_code_search_results", :force => true do |t|
    t.text     "result"
    t.integer  "start_index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uri"
  end

  create_table "ruby_codes", :force => true do |t|
    t.string   "path"
    t.string   "uri"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "clone_state"
    t.integer  "clone_attempts"
  end

end
