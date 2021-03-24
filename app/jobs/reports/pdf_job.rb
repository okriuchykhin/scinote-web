# frozen_string_literal: true

module Reports
  class PdfJob < ApplicationJob
    include InputSanitizeHelper

    queue_as :reports

    def perform(report, template_name, user, team, root_url)
      file = Tempfile.new(['report', '.pdf'])
      begin
        av = ActionView::Base.new
        # av.view_paths = ActionController::Base.view_paths
        # av.class_eval { include Rails.application.helpers }

        header_html = av.render(template: 'api/pdf/header.pdf.erb', layout: false)
        footer_html = av.render(template: 'api/pdf/header.pdf.erb', layout: false)
        pdf_html = av.render(template: @template, layout: false)

        file << WickedPdf.new.pdf_from_string(
          pdf_html,
          header: { content: header_html },
          footer: { content: footer_html }
        )

        report.pdf_file.attach(io: file, filename: 'report.pdf')
        report.update!(pdf_file_processing: false)

        report_path = Rails.application.routes.url_helpers.reports_path
        notification = Notification.create(
          type_of: :deliver,
          title: I18n.t('projects.reports.index.generation.completed_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{sanitize_input(report.name)}</a>",
                          team_name: sanitize_input(report.team.name))
        )
        notification.create_user_notification(user)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
