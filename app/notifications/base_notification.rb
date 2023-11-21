# frozen_string_literal: true

class BaseNotification < Noticed::Base
  deliver_by :database, if: :database_notification?
  deliver_by :email, mailer: 'NotificationMailer', method: :general_notification, if: :email_notification?

  def self.send_notifications(params, later: false)
    recipients_class =
      "Recipients::#{NotificationExtends::NOTIFICATIONS_TYPES[params[:type]][:recipients_module]}".constantize
    recipients_class.new(params).recipients.each do |recipient|
      if later
        with(params).deliver_later(recipient)
      else
        with(params).deliver(recipient)
      end
    end
  end

  def subtype
    params[:type]
  end

  def subject; end

  private

  def database_notification?
    recipient.notifications_settings.dig(notification_subgroup.to_s, 'in_app')
  end

  def email_notification?
    recipient.notifications_settings.dig(notification_subgroup.to_s, 'email')
  end

  def notification_subgroup
    NotificationExtends::NOTIFICATIONS_GROUPS.values.reduce({}, :merge).find do |_sg, n|
      n.include?(subtype.to_sym)
    end[0]
  end
end
