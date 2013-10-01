class PlanningComparisonService
  @@journal_sql = <<SQL
      select #{Journal.table_name}.id
        from journals
         inner join (select journable_id, max(created_at) as latest_date
                       from #{Journal.table_name}
                      where #{Journal.table_name}.created_at <= '#compare_date'
                   group by #{Journal.table_name}.journable_id) as latest
                 on #{Journal.table_name}.journable_id=latest.journable_id
           and #{Journal.table_name}.created_at=latest.latest_date
           and #{Journal.table_name}.journable_id in (#work_package_ids);
SQL
  @@mapped_attributes = Journal::WorkPackageJournal::journaled_attributes_keys.map{|attribute| "#{Journal::WorkPackageJournal.table_name}.#{attribute}"}.join ','

  @@work_package_select = <<SQL
      Select #{Journal.table_name}.journable_id as id,
             #{Journal.table_name}.created_at as created_at,
             #{Journal.table_name}.created_at as updated_at,
             #{@@mapped_attributes}
        from #{Journal::WorkPackageJournal.table_name}
        left join #{Journal.table_name}
               on #{Journal.table_name}.id = #{Journal::WorkPackageJournal.table_name}.journal_id
       where #{Journal::WorkPackageJournal.table_name}.id in (#journal_ids)
SQL

  # there is currently no possibility to compare two given dates:
  # the comparison always works on the current date, filters the current workpackages
  # and returns the state of these work_packages at the given time
  # filters are given in the format expected by Query and are just passed through to query
  def self.compare(project, compare_date, filter={})

    # The query uses three steps to find the journalized entries for the filtered workpackages
    # at the given point in time:
    # 1 filter the ids using query
    # 2 find out the latest journal-entries for the given date belonging to the filtered ids
    # 3 fetch the data for these journals from Journal::WorkPackageData
    # 4 fill theses journal-data into a workpackage

    # 1 either filter the ids using the given filter or pluck all work_package-ids from the project
    work_package_ids = if filter.has_key? :f
                         work_package_scope = WorkPackage.scoped
                                                         .joins(:status)
                                                         .joins(:project) #no idea, why query doesn't provide these joins itself...
                                                         .for_projects(project)
                                                         .without_deleted

                         query = Query.new
                         query.project = project
                         query.add_filters(filter[:f], filter[:op], filter[:v])
                         #TODO teach query to fetch only ids
                         work_package_scope.with_query(query)
                                           .map(&:id)
                       else
                         project.work_packages.pluck(:id)
                       end

    # 2 fetch latest journal-entries for the given time
    sql = @@journal_sql.gsub("#work_package_ids", work_package_ids.join(','))
                       .gsub("#compare_date", compare_date.strftime("%Y-%m-%d"))

    journal_ids = ActiveRecord::Base.connection.execute(sql)
                                               .map{|result| result["id"]}

    # use the journaled attributes to make the journal-entry appear like a real(tm) WorkPackage
    attributes = Journal::WorkPackageJournal::journaled_attributes_keys.map{|attribute| "#{Journal::WorkPackageJournal.table_name}.#{attribute}"}.join ','

    # 3 fetch the journaled data and make rails think it is actually a work_package
    work_packages = WorkPackage.find_by_sql(@@work_package_select.gsub('#journal_ids',journal_ids.join(',')))
  end
end