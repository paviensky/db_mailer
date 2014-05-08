module DbMailer
  class Delivery
    include Mail::CheckDeliveryParams

    ##
    # Initializes instance with settings. Typically settings are not passed directly but are
    # set during initialization process in Rails environment configurations like this
    #
    #   Rails.application.configure do
    #     config.action_mailer.db_settings = {
    #       # ...
    #     }
    #   end
    #
    # Or later through static attribute:
    #
    #   ActionMailer::Base.db_settings = {
    #   }
    #
    # == Settings
    #
    # [factory:String] name of the class that is responsible for persistence.
    # It can be name of any class with +create!+ method. This parameter is
    # mandatory.
    # [chain_delivery_method:Symbol] similar to <tt>ActionMailer::Base.delivery_method</tt>.
    # When set then the e-mail will be persisted and also delivered with this
    # deliver method.  (optionally when it passes through chain filter that
    # defaults to true)
    # [chain_filter:Proc] proc or lambda that is evaluated before e-mail is send
    # to chained delivery. If falsy value is returned then no chained delivery
    # will happen.
    #
    def initialize(settings)
      @factory_name = settings[:factory]
      @chain_delivery_method = settings[:chain_delivery_method]
      @chain_filter = settings[:chain_filter] || ->(m) {true}
    end

    ##
    # Default options for this delivery method
    #
    def self.default_options
      {
        :chain_delivery_method => nil,
        :chain_filter => nil
      }
    end

    ##
    # Delivers e-mail by saving it through configured factory and optionally
    # send it with chained delivery method
    #
    def deliver!(mail)
      # check validity
      check_delivery_params(mail)
      create_factory()

      persist_email(mail)

      chain_delivery(mail)
    end

    private
    # ==========================================================================

    ##
    # Creates factory (model) class from its name
    #
    def create_factory
      # get factory class
      begin
        @factory = @factory_name.constantize
      rescue
        # in case of trouble turn this into the sensible error
        raise ArgumentError.new("configured factory '#{@factory_name}' is not a valid class")
      end

      unless @factory.respond_to?(:create!)
        raise ArgumentError.new("configured factory '#{@factory_name}' is not a valid class (missing #create! method)")
      end
    end

    ##
    # Persists e-mail for each sender and recipient separately
    #
    def persist_email(mail)
      mail.from.each do |sender|
        mail.to.each do |recipient|
          @factory.create!(
            :from => sender,
            :to => recipient,
            :subject => mail.subject,
            :content => mail.encoded
          )
        end
      end
    end

    ##
    # Delivers e-mail through the chain if configured and if it passes through
    # filter.
    #
    def chain_delivery(mail)
      if @chain_delivery_method && @chain_filter.call(mail)
        mail.delivery_method(
          @chain_delivery_method,
          ActionMailer::Base.send("#{@chain_delivery_method}_settings")
        )
        mail.deliver
      end
    end

  end
end
