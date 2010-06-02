class ValidatesPresenceOfBelongsToController < ApplicationController
  def report
    @scholar = Scholarly::Scholars::ValidatesPresenceOfBelongsTo.run!
  end
end
