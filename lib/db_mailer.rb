require "action_mailer"
require 'mail/check_delivery_params'
require "db_mailer/version"
require "db_mailer/delivery"

module DbMailer
end

# register delivery method - we need to do it sooner then later as we need
# ActionMailer already extended during application's configuration code
ActionMailer::Base.add_delivery_method(
  :db,
  DbMailer::Delivery,
  DbMailer::Delivery.default_options
)
