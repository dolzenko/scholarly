class ToProcUsesController < ApplicationController
  def report
    start = Time.now
    @scholar = Scholarly::Scholars::ToProcUses.run!(params[:offset].to_i, params[:limit] || 1000)
    @elapsed_minutes = (Time.now - start) / 60
  end
end
