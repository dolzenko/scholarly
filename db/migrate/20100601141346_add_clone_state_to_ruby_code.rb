class AddCloneStateToRubyCode < ActiveRecord::Migration
  def self.up
    change_table :ruby_codes do |t|
      t.string :clone_state
    end
    RubyCode.update_all(:clone_state => "cloned")
  end

  def self.down
  end
end
