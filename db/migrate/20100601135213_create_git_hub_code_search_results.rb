class CreateGitHubCodeSearchResults < ActiveRecord::Migration
  def self.up
    create_table :git_hub_code_search_results do |t|
      t.text     "result"
      t.integer  "start_index"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uri"
    end
  end

  def self.down
    drop_table :git_hub_code_search_results
  end
end
