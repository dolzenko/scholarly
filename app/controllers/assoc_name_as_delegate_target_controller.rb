class AssocNameAsDelegateTargetController < ApplicationController
  def report
    @scholar = Scholarly::Scholars::AssocNameAsDelegateTarget.run!
  end
end
