# frozen_string_literal: true

class AddRepositorySnapshots < ActiveRecord::Migration[6.0]
  def up
    change_table :repositories, bulk: true do |t|
      t.string :type
      t.bigint :parent_id, null: true
      t.integer :status, null: true
      t.boolean :selected, null: true
      t.references :my_module
    end

    execute "UPDATE \"repositories\" SET \"type\" = 'Repository'"
    execute "UPDATE \"activities\" SET \"subject_type\" = 'RepositoryBase' WHERE \"subject_type\" = 'Repository'"

    add_column :repository_columns, :parent_id, :bigint, null: true
    add_column :repository_rows, :parent_id, :bigint, null: true

    remove_reference :repository_list_items, :repository, index: true, foreign_key: true
    remove_reference :repository_status_items, :repository, foreign_key: true
    remove_reference :repository_checklist_items, :repository, foreign_key: true
  end

  def down
    add_reference :repository_list_items, :repository, index: true, foreign_key: true
    add_reference :repository_status_items, :repository, index: true, foreign_key: true
    add_reference :repository_checklist_items, :repository, index: true, foreign_key: true

    remove_column :repository_columns, :parent_id
    remove_column :repository_rows, :parent_id

    execute "UPDATE \"activities\" SET \"subject_type\" = 'Repository' WHERE \"subject_type\" = 'RepositoryBase'"

    change_table :repositories, bulk: true do |t|
      t.remove :type
      t.remove :parent_id
      t.remove :status
      t.remove :selected
      t.remove_references :my_module
    end
  end
end
