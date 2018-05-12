# frozen_string_literal: true

module Interactors
  class AdjustEventStartTime
    include Interactors::Errors
    include BackgroundNotifiable

    def self.perform!(event, options)
      new(event, options).perform!
    end

    def initialize(event, options)
      @event = event
      @new_start_time = options[:new_start_time]
      @background_channel = options[:background_channel]
      @errors = []
    end

    def perform!
      if start_time_shift.zero?
        sleep(1)
      else
        ActiveRecord::Base.transaction do
          errors << resource_error_object(event) unless event.update(start_time: new_start_time)
          update_split_times unless errors.present?
          update_efforts unless errors.present?
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      report_interactor_response(response)
      response
    end

    private

    attr_reader :event, :new_start_time, :background_channel, :errors

    def update_split_times
      total_count = adjustable_split_times.size
      adjustable_split_times.each.with_index(1) do |st, index|
        report_progress(action: 'processed', resource: 'split time', current: index, total: total_count)
        next if errors.present?
        st.time_from_start -= start_time_shift
        errors << resource_error_object(st) unless st.save
      end
    end

    def update_efforts
      total_count = adjustable_efforts.size
      adjustable_efforts.each.with_index(1) do |effort, index|
        report_progress(action: 'processed', resource: 'effort', current: index, total: total_count)
        next if errors.present?
        effort.start_offset -= start_time_shift
        errors << resource_error_object(effort) unless effort.save
      end
    end

    def adjustable_split_times
      @adjustable_split_times ||= event.split_times.includes(:split).where.not(splits: {kind: :start}).where(efforts: {start_offset: 0})
    end

    def adjustable_efforts
      @adjustable_efforts ||= event.efforts.where.not(start_offset: 0)
    end

    def start_time_shift
      @start_time_shift ||= Time.parse(new_start_time) - event.start_time
    end

    def response
      Interactors::Response.new(errors, message, {})
    end

    def message
      if errors.present?
        "Unable to update event start time for #{event.name}. "
      elsif start_time_shift.zero?
        "Start time for #{event.name} was not changed. "
      else
        "Start time for #{event.name} was changed to #{event.start_time_in_home_zone}. Absolute split times were kept constant. "
      end
    end

    def adjustment_amount
      start_time_shift.positive? ? "backward by #{start_time_shift} seconds" : "forward by #{start_time_shift.abs} seconds"
    end
  end
end
