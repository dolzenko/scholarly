class AddIndexToRubyCodeOnClonedState < ActiveRecord::Migration
  def self.up
    add_index :ruby_codes, :clone_state
  end

  def self.down
  end
end
