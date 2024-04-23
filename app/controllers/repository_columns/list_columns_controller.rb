# frozen_string_literal: true

module RepositoryColumns
  class ListColumnsController < RepositoryColumnsController
    helper_method :delimiters

    def create
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :created, creating: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def update
      service = RepositoryColumns::UpdateListColumnService
                .call(user: current_user,
                      team: current_team,
                      column: @repository_column,
                      params: repository_column_update_params)

      if service.succeed?
        render json: service.column, status: :ok, editing: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def items
      column_list_items = if params[:all_options]
                            @repository_column.repository_list_items.select(:id, :data)
                          else
                            @repository_column.repository_list_items
                                              .where('data ILIKE ?', "%#{search_params[:query]}%")
                                              .limit(Constants::SEARCH_LIMIT)
                                              .select(:id, :data)
                          end

      render json: column_list_items.map { |i| { value: i.id, label: escape_input(i.data) } }, status: :ok
    end

    private

    def search_params
      params.permit(:query, :repository_id, :id)
    end

    def repository_column_params
      params
        .require(:repository_column)
        .permit(:name, metadata: [:delimiter], repository_list_items_attributes: %i(data))
    end

    def repository_column_update_params
      params
        .require(:repository_column)
        .permit(:name, repository_list_items_attributes: %i(data))
    end

    def delimiters
      Constants::REPOSITORY_LIST_ITEMS_DELIMITERS
        .split(',')
        .map { |e| Hash[t('libraries.manange_modal_column.list_type.delimiters.' + e), e] }
        .inject(:merge)
    end
  end
end
