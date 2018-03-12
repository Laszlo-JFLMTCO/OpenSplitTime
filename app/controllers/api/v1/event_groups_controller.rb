class Api::V1::EventGroupsController < ApiController
  include BackgroundNotifiable
  before_action :set_resource, except: [:index, :create]

  def show
    authorize @resource
    event_group = EventGroup.includes(organization: :stewards, events: [:efforts, :splits]).where(id: @resource.id).first
    render json: event_group, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  # Creates the given event_group and creates or updates relationships
  # all in a single transaction.

  # POST /api/v1/event_groups
  def create
    event_group = EventGroup.new
    event_relationships = params.dig(:data, :relationships, :events, :data) || []
    events = event_relationships.map { |relationship| Event.find_or_initialize_by(id: relationship[:id]) }
    courses = events.map { |event| event.course || Course.new }
    organization = Organization.find_or_initialize_by(id: params.dig(:data, :relationships, :organization, :data, :id))

    persisted_resources = [event_group, events, courses, organization].flatten.select(&:persisted?)
    skip_authorization if persisted_resources.empty?
    persisted_resources.each { |resource| authorize resource }

    response = Interactors::PersistEventGroup.perform!(event_group, events: events, courses: courses, organization: organization, params: params)

    if response.successful?
      event_group.reload
      render json: event_group, include: 'events.course, organization', status: :created
    else
      render json: {errors: response.resources.map { |resource| jsonapi_error_object(resource) if resource.errors.present? }}, status: :unprocessable_entity
    end
  end

  def pull_live_time_rows

    # This endpoint searches for un-pulled live_times belonging to the event_group, selects a batch,
    # marks them as pulled, combines them into live_time_rows, and returns them
    # to the group live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, live_times without a matching split_time will be pulled
    # even if they are marked as already having been pulled.

    authorize @resource

    if @resource.available_live
      force_pull = params[:force_pull]&.to_boolean
      live_times_default_limit = 50
      live_times_limit = (params[:page] && params[:page][:size]) || live_times_default_limit

      scoped_live_times = force_pull ? @resource.live_times.unmatched : @resource.live_times.unconsidered

      # Order should be by absolute time, and where absolute time is nil, then by entered time.
      # This ordering is important to minimize the risk of incorrectly ordered times in multi-lap events.
      selected_live_times = scoped_live_times.order(:absolute_time, :entered_time).limit(live_times_limit)

      grouped_live_times = selected_live_times.group_by(&:event_id)

      live_time_rows = grouped_live_times.flat_map do |event_id, live_times|
        event = Event.where(id: event_id).includes(:splits, :course).first
        LiveTimeRowConverter.convert(event: event, live_times: live_times)
      end

      selected_live_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
      report_live_times_available(@resource)
      render json: {returnedRows: live_time_rows}, status: :ok
    else
      render json: live_entry_unavailable(@resource), status: :forbidden
    end
  end

  def trigger_live_times_push
    authorize @resource
    report_live_times_available(@resource)
    render json: {message: "Live times push notification sent for #{@resource.name}"}
  end

  private

  def authorize_param_resources
    primary_type_id = (params[:data] || {}).slice(:type, :id)
    included_type_ids = (params[:included] || []).map { |include| include.slice(:id, :type) }

    (Array.wrap(primary_type_id) + included_type_ids).each do |type_id|
      type_id[:id] ? authorize_persisted_resource(type_id) : authorize_new_resource(type_id)
    end
    skip_authorization # Keeps Pundit from raising error if no resources are available
  end

  def authorize_persisted_resource(type_id)
    persisted_included_resource = type_id[:type].classify.constantize.find(type_id[:id])
    authorize persisted_included_resource if persisted_included_resource
  end

  def authorize_new_resource(type_id)
    authorize type_id[:type].classify.constantize
  end
end
