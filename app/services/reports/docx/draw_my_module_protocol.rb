# frozen_string_literal: true

module Reports::Docx::DrawMyModuleProtocol
  def draw_my_module_protocol(_subject, my_module)
    return unless my_module

    protocol = my_module.protocol
    return false if protocol.description.blank?

    @docx.p I18n.t 'projects.reports.elements.module.protocol.user_time',
                   timestamp: I18n.l(protocol.created_at, format: :full)
    @docx.hr
    html = custom_auto_link(protocol.description, team: @report_team)
    html_to_word_converter(html)
    @docx.p
    @docx.p
  end
end
