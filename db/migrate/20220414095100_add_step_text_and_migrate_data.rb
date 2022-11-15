# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddStepTextAndMigrateData < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    create_table :step_texts do |t|
      t.references :step, null: false, index: true, foreign_key: true
      t.string :text

      t.timestamps
    end

    add_gin_index_without_tags :step_texts, :text

    ActiveRecord::Base.connection.execute(
      'INSERT INTO step_texts(step_id, text, created_at, updated_at) '\
      'SELECT id, description, created_at, updated_at FROM steps ' \
      'WHERE steps.description IS NOT NULL'
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE tiny_mce_assets SET object_type = 'StepText', object_id = step_texts.id "\
      "FROM steps "\
      "JOIN step_texts ON steps.id = step_texts.step_id "\
      "WHERE steps.id = tiny_mce_assets.object_id AND tiny_mce_assets.object_type = 'Step'"
    )
  end

  def down
    StepText.joins(:tiny_mce_assets)
            .preload(:step, :tiny_mce_assets).find_each do |step_text|
      step_text.tiny_mce_assets.update_all(object_type: 'Step', object_id: step_text.step.id)
    end

    drop_table :step_texts
  end
end
