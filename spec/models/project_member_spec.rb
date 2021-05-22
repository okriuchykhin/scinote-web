# frozen_string_literal: true

require 'rails_helper'

describe ProjectMember, type: :model do
  let(:owner_role) { create :owner_role }
  let!(:project) { create :project }
  let!(:user) { create :user }
  let(:normal_user_role) { create :normal_user_role }

  let(:subject) { described_class.new(user, project, user) }

  describe 'create' do
    it 'create a user_assignment and user_project records' do
      subject.assign = true
      subject.user_role_id = owner_role.id
      expect{
        subject.create
      }.to change(UserProject, :count).by(1).and \
           change(UserAssignment, :count).by(1)
    end

    it 'logs a assign_user_to_project activity' do
      subject.assign = true
      subject.user_role_id = owner_role.id
      expect{
        subject.create
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'assign_user_to_project'
    end
  end

  describe 'update' do
    let!(:user_project) { create :user_project, user: user, project: project }
    let!(:user_assignment) {
      create :user_assignment,
             assignable: project,
             user: user,
             user_role: owner_role,
             assigned_by: user
    }

    it 'updates only the user assignment role' do
      subject.user_role_id = normal_user_role.id
      subject.update
      expect(user_assignment.reload.user_role).to eq normal_user_role
    end

    it 'logs a change_user_role_on_project activity' do
      subject.user_role_id = normal_user_role.id
      expect{
        subject.update
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_project'
    end
  end

  describe 'destroy' do
    let!(:user_two) { create :user }
    let!(:user_project_two) { create :user_project, user: user_two, project: project }
    let!(:user_assignment_two) {
      create :user_assignment,
             assignable: project,
             user: user_two,
             user_role: owner_role,
             assigned_by: user
    }
    let!(:user_project) { create :user_project, user: user, project: project }
    let!(:user_assignment) {
      create :user_assignment,
             assignable: project,
             user: user,
             user_role: owner_role,
             assigned_by: user
    }

    it 'removes the user_assignment and user_project' do
      expect {
        subject.destroy
      }.to change(UserAssignment, :count).by(-1).and \
           change(UserProject, :count).by(-1)
    end

    it 'does not remove the user_assignment and user_project if the user is last owner' do
      user_assignment_two.update!(user_role: normal_user_role)

      expect {
        subject.destroy
      }.to change(UserAssignment, :count).by(0).and \
           change(UserProject, :count).by(0)
    end

    it 'logs a unassign_user_from_project activity' do
      expect{
        subject.destroy
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'unassign_user_from_project'
    end
  end

  describe 'validations' do
    it 'validates presence or user, project, user_role_id when assign is true' do
      subject = described_class.new(nil, nil)
      subject.assign = true
      subject.valid?
      expect(subject.errors).to have_key(:project)
      expect(subject.errors).to have_key(:user)
      expect(subject.errors).to have_key(:user_role_id)
    end

    it 'validates user project relation existence' do
      create :user_project, project: project, user: user
      subject.assign = true
      subject.valid?
      expect(subject.errors).to have_key(:user)
    end

    it 'validates user project assignment existence' do
      create :user_assignment, assignable: project, user: user, user_role: owner_role, assigned_by: user
      subject.assign = true
      subject.user_role_id = owner_role.id
      subject.valid?
      expect(subject.errors).to have_key(:user_role_id)
    end

    describe 'user_role' do
      it 'adds an error when user role does not exist' do
        subject.assign = true
        subject.user_role_id = 1234
        subject.valid?
        expect(subject.errors).to have_key(:user_role_id)
      end

      it 'does not add an error when role exists' do
        subject.assign = true
        subject.user_role_id = owner_role.id
        subject.valid?
        expect(subject.errors).not_to have_key(:user_role_id)
      end
    end
  end
end
