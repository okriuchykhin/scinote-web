# frozen_string_literal: true

module Lists
  class ExperimentSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :name, :code, :created_at, :updated_at, :workflow_img, :description, :completed_tasks,
               :total_tasks, :archived_on, :urls

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def archived
      object.archived_branch?
    end

    def archived_on
      I18n.l(object.archived_on || object.project.archived_on, format: :full_date) if archived
    end

    def completed_tasks
      object[:completed_task_count]
    end

    def total_tasks
      object[:task_count]
    end

    def urls
      {
        show: table_experiment_path(object),
        actions: actions_toolbar_experiments_path(items: [{ id: object.id }].to_json),
        projects_to_clone: projects_to_clone_experiment_path(object),
        projects_to_move: projects_to_move_experiment_path(object),
        clone: clone_experiment_path(object),
        move: move_experiment_path(object)
      }
    end

    def workflow_img
      rails_blob_path(object.workflowimg, only_path: true) if object.workflowimg.attached?
    end
  end
end
