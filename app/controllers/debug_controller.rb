class DebugController < ApplicationController
  def debug
    @scholar = Scholarly::Scholars::AssocNameAsDelegateTarget.run!
  end
end
