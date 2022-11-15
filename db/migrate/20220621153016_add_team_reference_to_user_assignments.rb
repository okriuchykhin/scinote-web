# frozen_string_literal: true

class AddTeamReferenceToUserAssignments < ActiveRecord::Migration[6.1]
  def up
    add_reference :user_assignments, :team, index: true, foreign_key: true
    UserAssignment.reset_column_information

    ActiveRecord::Base.connection.execute(
      "UPDATE user_assignments SET team_id = projects.team_id "\
      "FROM projects " \
      "WHERE user_assignments.assignable_type = 'Project' AND user_assignments.assignable_id = projects.id"
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE user_assignments SET team_id = projects.team_id "\
      "FROM experiments " \
      "JOIN projects ON projects.id = experiments.project_id "\
      "WHERE user_assignments.assignable_type = 'Experiment' AND user_assignments.assignable_id = experiments.id"
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE user_assignments SET team_id = projects.team_id "\
      "FROM my_modules " \
      "JOIN experiments ON experiments.id = my_modules.experiment_id "\
      "JOIN projects ON projects.id = experiments.project_id "\
      "WHERE user_assignments.assignable_type = 'MyModule' AND user_assignments.assignable_id = my_modules.id"
    )

    UserAssignment.where(team_id: nil).preload(:assignable).find_each do |user_assignment|
      next if user_assignment.assignable.blank?

      team = user_assignment.assignable.is_a?(Team) ? user_assignment.assignable : user_assignment.assignable.team
      user_assignment.update_column(:team_id, team.id)
    end
  end

  def down
    remove_reference :user_assignments, :team, index: true, foreign_key: true
  end
end
