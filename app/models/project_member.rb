# frozen_string_literal: true

class ProjectMember
  include ActiveModel::Model

  attr_accessor :user, :project, :assign, :user_role_id, :user_id
  attr_reader :current_user, :user_assignment, :user_role

  delegate :user_role, to: :user_assignment, allow_nil: true

  validates :user, :project, presence: true, if: -> { assign }
  validates :user_role_id, presence: true, if: -> { assign }
  validate :validate_role_presence, if: -> { assign }
  validate :validate_user_project_relation_presence, if: -> { assign }
  validate :validate_user_project_assignment_presence, if: -> { assign }

  def initialize(user, project, current_user = nil)
    @user = user
    @project = project
    @current_user = current_user
    @user_assignment = UserAssignment.find_by(assignable: @project, user: @user)
  end

  def create
    return unless assign

    ActiveRecord::Base.transaction do
      UserProject.create!(project: @project, user: @user)
      @user_assignment = UserAssignment.create!(
        assignable: @project,
        user: @user,
        user_role: set_user_role,
        assigned_by: current_user
      )
      log_activity(:assign_user_to_project)
    end
  end

  def update
    validate_role_presence
    return false unless valid?

    ActiveRecord::Base.transaction do
      user_assignment = UserAssignment.find_by!(assignable: @project, user: @user)
      user_assignment.update!(user_role: set_user_role)
      log_activity(:change_user_role_on_project)
    end
  end

  def destroy
    user_assignment = UserAssignment.find_by!(assignable: @project, user: @user)
    user_project = UserProject.find_by!(project: @project, user: @user)
    return false if last_project_owner?

    ActiveRecord::Base.transaction do
      user_assignment.destroy!
      user_project.destroy!
      log_activity(:unassign_user_from_project)
    end
  end

  def assign=(value)
    @assign = ActiveModel::Type::Boolean.new.cast(value)
  end

  def last_project_owner?
    project_owners.count == 1 && user_role.owner?
  end

  private

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: project,
            team: project.team,
            project: project,
            message_items: { project: project.id,
                             user_target: user.id,
                             role: user_role.name })
  end

  def set_user_role
    UserRole.find(user_role_id)
  end

  def validate_role_presence
    errors.add(:user_role_id, :not_found) if UserRole.find_by(id: user_role_id).nil?
  end

  def validate_user_project_relation_presence
    return if UserProject.find_by(project: @project, user: @user).nil?
    errors.add(:user)
  end

  def validate_user_project_assignment_presence
    return if  UserAssignment.find_by(assignable: @project, user: @user).nil?
    errors.add(:user_role_id, :already_present)
  end

  def project_owners
    @project_owners ||= @project.user_assignments
                                .includes(:user_role)
                                .where(user_roles: { name: 'Owner' })
  end
end
