# frozen_string_literal: true

module Interactors
  module Errors
    def resource_error_object(record)
      {title: "#{record.class} #{record} could not be saved",
       detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
    end

    def active_record_error(exception)
      {title: 'An ActiveRecord exception occurred',
       detail: {exception: exception}}
    end

    def cannot_unstart_error(effort)
      {title: "Cannot mark #{effort} as DNS",
       detail: {messages: ['The effort has one or more intermediate or finish times recorded. Times must be deleted from the effort view.']}}
    end

    def distance_mismatch_error(child, new_parent)
      {title: 'Distances do not match',
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because distances do not coincide"]}}
    end

    def lap_mismatch_error(child, new_parent)
      {title: 'Distances do not match',
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because laps exceed maximum required"]}}
    end

    def live_time_mismatch_error
      {title: 'Live times do not match',
       detail: {messages: ['One or more live times is not related to the provided event']}}
    end

    def missing_effort_error
      {title: 'Missing effort',
      detail: {messages: ['The raw_time is missing an effort']}}
    end

    def missing_new_split_time_error(raw_time)
      {title: 'Raw time does not contain a new_split_time',
      detail: {messages: ["#{raw_time} does not have a new_split_time"]}}
    end

    def raw_time_mismatch_error
      {title: 'Raw times do not match',
       detail: {messages: ['One or more raw times is not related to the provided event group']}}
    end

    def sub_split_mismatch_error(child, new_parent)
      {title: 'Distances do not match',
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because sub splits do not coincide"]}}
    end

    def mismatched_organization_error(old_event_group, new_event_group)
      {title: 'Event group organizations do not match',
       detail: {messages: ["The event cannot be updated because #{old_event_group} is organized under #{old_event_group.organization}, but #{new_event_group} is organized under #{new_event_group.organization}"]}}
    end

    def effort_offset_failure_error(effort)
      {title: 'Effort offset could not be adjusted',
       detail: {messages: ["The starting split time for #{effort} was beyond an existing later split time"]}}
    end
  end
end
