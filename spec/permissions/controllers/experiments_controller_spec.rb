# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    new: { project_id: 1 },
    create: { project_id: 1 },
    show: { id: 1 },
    canvas: { id: 1 },
    edit: { id: 1 },
    update: { id: 1 },
    archive: { id: 1 },
    archive_group: { project_id: 1 },
    restore_group: { project_id: 1 },
    clone: { id: 1 },
    move: { id: 1 },
    module_archive: { id: 1 },
    fetch_workflow_img: { id: 1 },
    sidebar: { id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    it_behaves_like "a controller action with permissions checking", :get, :new do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::EXPERIMENTS_CREATE] }
      let(:action_params) { { project_id: project.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::EXPERIMENTS_CREATE] }
      let(:action_params) { { project_id: project.id, experiment: { name: 'Test' } } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :canvas do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :edit do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::MANAGE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::MANAGE, ExperimentPermissions::RESTORE] }
      let(:action_params) { { id: experiment.id, experiment: { name: 'Test1' } } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :archive do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::ARCHIVE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :archive_group do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::ARCHIVE] }
      let(:action_params) { { project_id: project.id, experiments_ids: [experiment.id] } }
      let(:custom_response_status) { :unprocessable_entity }
    end

    it_behaves_like "a controller action with permissions checking", :post, :restore_group do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::RESTORE] }
      let(:action_params) { { project_id: project.id, experiments_ids: [experiment.id] } }
      let(:custom_response_status) { :unprocessable_entity }
    end

    it_behaves_like "a controller action with permissions checking", :get, :clone_modal do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::CLONE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :clone do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::CLONE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :move_modal do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::MOVE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :move do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::MOVE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :module_archive do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :fetch_workflow_img do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :sidebar do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end
  end
end
