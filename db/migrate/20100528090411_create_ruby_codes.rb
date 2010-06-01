class CreateRubyCodes < ActiveRecord::Migration
  def self.up
    create_table :ruby_codes do |t|
      t.string :path
      t.string :uri
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :ruby_codes
  end
end
