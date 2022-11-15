# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')
class GenerateStepOrderableRelation < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    ActiveRecord::Base.connection.execute(
      "INSERT INTO step_orderable_elements(step_id, position, orderable_type, orderable_id, created_at, updated_at) "\
      "SELECT steps.id, (ROW_NUMBER () OVER (PARTITION BY step_texts.step_id ORDER BY step_texts.id) - 1), "\
      "'StepText', step_texts.id, NOW(), NOW() "\
      "FROM step_texts "\
      "JOIN steps ON steps.id = step_texts.step_id"
    )

    ActiveRecord::Base.connection.execute(
      "INSERT INTO step_orderable_elements(step_id, position, orderable_type, orderable_id, created_at, updated_at) "\
      "SELECT steps.id, "\
        "(ROW_NUMBER () OVER (PARTITION BY step_tables.step_id ORDER BY step_tables.id) + COUNT(step_orderable_elements.id) - 1), "\
        "'StepTable', step_tables.id, NOW(), NOW() "\
      "FROM step_tables "\
      "JOIN steps ON steps.id = step_tables.step_id "\
      "LEFT OUTER JOIN step_orderable_elements ON step_orderable_elements.step_id = steps.id "\
      "GROUP BY step_tables.id, steps.id"
    )

    ActiveRecord::Base.connection.execute(
      "INSERT INTO step_orderable_elements(step_id, position, orderable_type, orderable_id, created_at, updated_at) "\
      "SELECT steps.id, "\
        "(ROW_NUMBER () OVER (PARTITION BY checklists.step_id ORDER BY checklists.id) + COUNT(step_orderable_elements.id) - 1), "\
        "'Checklist', checklists.id, NOW(), NOW() "\
      "FROM checklists "\
      "JOIN steps ON steps.id = checklists.step_id "\
      "LEFT OUTER JOIN step_orderable_elements ON step_orderable_elements.step_id = steps.id "\
      "GROUP BY checklists.id, steps.id"
    )
  end

  def down
    StepOrderableElement.delete_all
  end
end
