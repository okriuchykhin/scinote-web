class TeamImporter
  def import_from_json(file_path)
    Zip::File.open(file_path) do |zip_file|
      # Find specific entry
      entry = zip_file.glob('team_export.json').first
      team_json = JSON.parse(entry.get_input_stream.read)
      team = Team.new(team_json['team'])
      pp team
      orig_team_id = team.id
      team.id = nil
      team.transaction do
        team.save!
        pp team
        user_mappings = {}
        team_json['users'].each do |user_json|
          user = User.new(user_json['user'])
          pp user
          orig_user_id = user.id
          user.id = nil
          user.save!
          user_mappings[orig_user_id] = user.id
        end
        puts user_mappings
        raise ActiveRecord:: Rollback
      end
      team_json
    end
  end
end
