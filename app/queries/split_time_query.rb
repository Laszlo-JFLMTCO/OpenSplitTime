class SplitTimeQuery

  def self.with_time_point_rank(split_time_fields: '*')
    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        split_times_scoped AS (SELECT split_times.*
                                       FROM split_times
                                       INNER JOIN existing_scope ON existing_scope.id = split_times.id)

      SELECT *, 
            rank() over 
                (PARTITION BY lap, 
                              split_id, 
                              sub_split_bitkey 
                ORDER BY subquery_time, 
                         effort_gender desc, 
                         effort_age desc,
                         tiebreaker_id) 
            as time_point_rank
      FROM
          (SELECT time_from_start as subquery_time, #{split_time_fields}, 
            (events.start_time + efforts.start_offset * interval '1 second' + time_from_start * interval '1 second') as day_and_time,
            efforts.gender as effort_gender, efforts.age as effort_age, efforts.id as tiebreaker_id
          FROM split_times_scoped
          INNER JOIN efforts ON efforts.id = split_times_scoped.effort_id
          INNER JOIN events ON events.id = efforts.event_id
          WHERE time_from_start > 0) 
          AS subquery
      ORDER BY time_point_rank
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    SplitTime.connection.unprepared_statement { SplitTime.reorder(nil).select("id").to_sql }
  end
end