class AddCloneAttemptsToRubyCode < ActiveRecord::Migration
  def self.up
    change_table :ruby_codes do |t|
      t.integer :clone_attempts
    end
  end

  def self.down
  end
end
