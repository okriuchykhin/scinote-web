# frozen_string_literal: true

module Api
  module V1
    class RepositoryChecklistValueSerializer < ActiveModel::Serializer
      attribute :checklist_item_ids
      attribute :formatted

      has_many :repository_checklist_items,
               key: :inventory_checklist_items,
               serializer: InventoryChecklistItemSerializer,
               class_name: 'RepositoryChecklistItem'

      def checklist_item_ids
        object.repository_checklist_items.pluck(:id)
      end
    end
  end
end
