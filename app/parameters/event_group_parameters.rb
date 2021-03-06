# frozen_string_literal: true

class EventGroupParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :organization_id, :concealed, :available_live, :monitor_pacers, :auto_live_times, :data_entry_grouping_strategy]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + RawTimeParameters.permitted_query
  end
end
