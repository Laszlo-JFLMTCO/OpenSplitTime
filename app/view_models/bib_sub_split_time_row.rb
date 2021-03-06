# frozen_string_literal: true

class BibSubSplitTimeRow
  DISCREPANCY_THRESHOLD = 5.minutes
  attr_reader :bib_number, :effort

  def initialize(args)
    @bib_number = args[:bib_number]
    @effort = args[:effort] || Effort.null_record
    @time_records = args[:time_records] || []
    @split_times = args[:split_times] || []
    @event_group = args[:event_group]
  end

  def full_name
    effort.full_name.strip.presence || '[Bib not found]'
  end

  def recorded_times
    time_records.group_by(&:source_text).transform_values do |times_array|
      {military_times: times_array.map { |tr| tr.military_time(time_zone) || tr.entered_time },
       split_time_ids: times_array.map(&:split_time_id)}
    end
  end

  def result_times
    split_times.map do |split_time|
      {lap: split_time.lap,
       military_time: split_time.military_time,
       data_status: split_time.data_status,
       time_and_optional_lap: time_and_optional_lap(split_time)}
    end
  end

  def largest_discrepancy
    times_in_seconds = joined_military_times.map { |military_time| ActiveSupport::TimeZone[time_zone].parse(military_time).seconds_since_midnight }.sort
    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    (adjusted_times.last - adjusted_times.first).to_i
  end

  def problem?
    (largest_discrepancy > DISCREPANCY_THRESHOLD) || effort.null_record?
  end

  private

  attr_reader :time_records, :split_times, :event_group

  def time_and_optional_lap(split_time)
    event_group.multiple_laps? ? "Lap #{split_time.lap}: #{split_time.military_time}" : split_time.military_time
  end

  def time_zone
    event_group.home_time_zone
  end

  def joined_military_times
    split_times.map(&:military_time) | time_records.map { |tr| tr.military_time(time_zone) }.compact
  end
end
