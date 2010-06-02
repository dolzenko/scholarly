class ToProcUsesController < ApplicationController
  def report
    @scholar = Scholarly::Scholars::ToProcUses.run!
  end

  module Qwe
    def to_proc
      123
    end
  end
end
