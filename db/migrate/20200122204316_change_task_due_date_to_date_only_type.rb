# frozen_string_literal: true

class ChangeTaskDueDateToDateOnlyType < ActiveRecord::Migration[6.0]
  def change
    change_column :my_modules, :due_date, :date
  end
end
