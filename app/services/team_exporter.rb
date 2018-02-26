require 'zip'
require 'fileutils'

class TeamExporter
  def initialize(team_id)
    @team = Team.includes(:user_teams).find_by_id(team_id)
    raise StandardError, 'Can not load team' unless @team
    @admin_id = @team.users.where('user_teams.role': 'admin').first.id
    @assets_to_copy = []
    @tiny_mce_assets_to_copy = []
  end

  def export_to_zip
    file = File.new(
      File.join(Rails.root, "tmp/team_export_#{Time.now.to_i}.zip"),
      'w+'
    )
    @team.transaction(isolation: :serializable) do
      dir_to_zip = FileUtils.mkdir_p(
        File.join("tmp/team_export_#{Time.now.to_i}")
      ).first

      # Writing JSON file with team structure
      File.write(
        File.join(dir_to_zip, 'team_export.json'),
        team(@team).to_json
      )
      # Copying assets
      copy_files(@assets_to_copy, File.join(dir_to_zip, 'assets'))
      # Copying tiny_mce_assets
      copy_files(@tiny_mce_assets_to_copy,
                 File.join(dir_to_zip, 'tiny_mce_assets'))

      entries =
        Dir.glob(File.join(dir_to_zip, '**', '*'))
           .reject { |e| File.directory?(e) }
      Zip::File.open(file.path, Zip::File::CREATE) do |zipfile|
        entries.each do |e|
          puts "entry: #{e}"
          zipfile.add(e.remove(dir_to_zip, %r{^\/}), e)
        end
      end
    end
  # ensure
  #   file.close unless file.nil?
  end

  private

  def copy_files(assets, dir_name)
    assets.flatten.each do |a|
      dir = FileUtils.mkdir_p(File.join(dir_name, a.id.to_s)).first
      if S3_BUCKET
        s3_asset = S3_BUCKET.object(a.file.path.remove(%r{^/}))
        next unless s3_asset.exists?
        File.open(File.join(dir, a.file.original_filename), 'wb') do |f|
          s3_asset.get(response_target: f)
        end
      else
        FileUtils.cp(
          a.file.path,
          File.join(dir, a.file.original_filename)
        )
      end
    end
  end

  def team(team)
    if team.tiny_mce_assets.present?
      @tiny_mce_assets_to_copy.push(team.tiny_mce_assets)
    end
    {
      team: team,
      users: team.users.map { |u| user(u) },
      user_teams: team.user_teams,
      notifications: Notification
        .includes(:user_notifications)
        .where('user_notifications.user': team.users),
      samples: team.samples.map { |s| sample(s) },
      sample_groups: team.sample_groups,
      sample_types: team.sample_types,
      custom_fields: team.custom_fields,
      repositories: team.repositories.map { |r| repository(r) },
      tiny_mce_assets: team.tiny_mce_assets,
      protocol_keywords: team.protocol_keywords,
      projects: team.projects.map { |p| project(p) }
    }
  end

  def user(user)
    {
      user: user,
      user_notifications: user.user_notifications,
      user_identities: user.user_identities,
      samples_tables: user.samples_tables.where(team: @team),
      repository_table_states:
        user.repository_table_states.where(repository: @team.repositories)
    }
  end

  def project(project)
    {
      project: project,
      user_projects: project.user_projects,
      activities: project.activities,
      project_comments: project.project_comments,
      reports: project.reports.map { |r| report(r) },
      experiments: project.experiments.map { |e| experiment(e) },
      tags: project.tags
    }
  end

  def report(report)
    {
      report: report,
      report_elements: report.report_elements
    }
  end

  def experiment(experiment)
    {
      experiment: experiment,
      my_modules:  experiment.my_modules.map { |m| my_module(m) },
      my_module_groups: experiment.my_module_groups,
      activities: experiment.activities
    }
  end

  def my_module(my_module)
    {
      my_module: my_module,
      inputs: my_module.inputs,
      outputs: my_module.outputs,
      my_module_tags: my_module.my_module_tags,
      task_comments: my_module.task_comments,
      my_module_repository_rows: my_module.my_module_repository_rows,
      sample_my_modules: my_module.sample_my_modules,
      activities: my_module.activities,
      user_my_modules: my_module.user_my_modules,
      protocols: my_module.protocols.map { |pr| protocol(pr) },
      results: my_module.results.map { |res| result(res) }
    }
  end

  def protocol(protocol)
    {
      protocol: protocol,
      protocol_protocol_keywords: protocol.protocol_protocol_keywords,
      steps: protocol.steps.map { |s| step(s) }
    }
  end

  def step(step)
    @assets_to_copy.push(step.assets.to_a) if step.assets.present?
    {
      step: step,
      checklists: step.checklists.map { |c| checklist(c) },
      step_comments: step.step_comments,
      step_assets: step.step_assets,
      assets: step.assets,
      step_tables: step.step_tables,
      tables: step.tables
    }
  end

  def checklist(checklist)
    {
      checklist: checklist,
      checklist_items: checklist.checklist_items
    }
  end

  def result(result)
    @assets_to_copy.push(result.asset) if result.asset.present?
    {
      result: result,
      result_comments: result.result_comments,
      result_asset: result.result_asset,
      asset: result.asset,
      result_table: result.result_table,
      table: result.table,
      result_text: result.result_text
    }
  end

  def sample(sample)
    {
      sample: sample,
      sample_custom_fields: sample.sample_custom_fields
    }
  end

  def repository(repository)
    {
      repository: repository,
      repository_columns: repository.repository_columns,
      repository_rows: repository.repository_rows.map do |r|
        repository_row(r)
      end
    }
  end

  def repository_row(repository_row)
    {
      repository_row: repository_row,
      my_module_repository_rows: repository_row.my_module_repository_rows,
      repository_cells: repository_row.repository_cells.map do |c|
        repository_cell(c)
      end
    }
  end

  def repository_cell(cell)
    {
      repository_cell: cell,
      repository_value: cell.value
    }
  end
end
