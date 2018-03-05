module Interactors
  class PersistEventGroup
    include Interactors::Errors

    def self.perform!(event_group, args)
      new(event_group, args).perform!
    end

    def initialize(event_group, args)
      @event_group = event_group
      @events = args[:events]
      @courses = args[:courses]
      @organization = args[:organization]
      @params = args[:params]
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        submitted_resources.each do |resource|
          update_resource(resource)
        end
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :event_group, :events, :courses, :organization, :params, :errors

    def submitted_resources
      [courses, organization, event_group, events].flatten
    end

    def update_resource(resource)
      if resource.update(resource_params(resource))
        resource.reload
      else
        errors << resource_error_object(resource)
      end
    end

    def resource_params(resource)

    end

    def message
      errors.present? ? 'Event group and relationships were saved. ' : 'Event group and relationships could not be saved. '
    end
  end
end
