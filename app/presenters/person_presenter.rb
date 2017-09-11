class PersonPresenter < BasePresenter

  def initialize(person, params)
    @person = person
    @params = params
  end

  def efforts
    @efforts ||= EffortPolicy::Scope.new(current_user, Effort).viewable.with_ordered_split_times
                     .where(person: person).sort_by { |effort| -effort.start_time.to_i }
  end

  def method_missing(method)
    person.send(method)
  end

  private

  attr_reader :person, :params
end