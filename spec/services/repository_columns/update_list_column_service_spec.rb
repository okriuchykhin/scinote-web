# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::UpdateListColumnService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:repository) { create :repository, team: team }
  let(:column) { create :repository_column, :list_type }
  let(:list_item) { create(:repository_list_item, repository: repository, repository_column: column) }
  let(:service_call) do
    RepositoryColumns::UpdateListColumnService.call(column: column,
                                                    user: user,
                                                    team: team,
                                                    params: params)
  end

  context 'when updates column name' do
    let(:params) { { name: 'my new column' } }

    it 'updates RepositoryColumn record' do
      column

      expect { service_call }.to change(column, :name)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.count }.by(1))
    end
  end

  context 'when changing list items' do
    let(:column) { create :repository_column, :list_type }
    let(:list_item) { create(:repository_list_item, repository: repository, repository_column: column) }

    context 'when adding list item' do
      let(:params) do
        {
          repository_list_items_attributes: [
            { data: list_item.data },
            { data: 'new added list item' }
          ]
        }
      end

      it 'removes RepositoryStatusItem record' do
        list_item

        expect { service_call }.to(change { RepositoryListItem.count }.by(1))
      end
    end

    context 'when deleting list item' do
      let(:params) do
        {
          repository_list_items_attributes: []
        }
      end

      it 'removes RepositoryStatusItem record' do
        list_item

        expect { service_call }.to(change { RepositoryListItem.count }.by(-1))
      end
    end

    context 'when there is more than 500 items' do
      let(:params) do
        {
          repository_list_items_attributes: Array(1..510).map { |e| { data: "Item #{e}" } }
        }
      end

      it 'returns error about repository_list_item' do
        column

        expect(service_call.errors[:repository_column]).to have_key(:repository_list_items)
      end

      it 'no items has been inserted' do
        expect { service_call }.to(change { RepositoryListItem.count }.by(0))
      end
    end

    context 'when there not valid item' do
      let(:params) do
        {
          repository_list_items_attributes: [
            { data: 'first item' },
            { data: 'second item' },
            { data: 'third item' },
            { data: 'Too long item' * 3000 }
          ]
        }
      end

      it 'returns error about wrong item' do
        expect(service_call.errors[:repository_column]).to have_key(:repository_list_item)
      end

      it 'does not insert any items' do
        expect { service_call }.to(change { RepositoryListItem.count }.by(0))
      end

      it 'does not add Activity record' do
        expect { service_call }.not_to(change { Activity.count })
      end
    end
  end
end
