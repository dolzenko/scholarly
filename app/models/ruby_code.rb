class RubyCode < ActiveRecord::Base
  validates :uri, :uniqueness => true
end
