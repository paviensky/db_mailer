require "spec_helper"

describe DbMailer::Delivery do
  let(:mail) { ActionMailer::Base.mail(
    :from => "someone@somewhere.com",
    :to => "foo@bar.com",
    :subject => "hey",
    :body => "")
  }

  let(:factory) {
    factory = double("emailFactory",
      :create! => true
    )

    allow(factory).to receive(:constantize).and_return(factory)

    factory
  }

  before :each do
    ActionMailer::Base.delivery_method = :db
  end

  # ============================================================================

  describe 'extensions' do
    it 'extends action mailer with db settings' do
      expect(ActionMailer::Base).to respond_to(:db_settings)
      expect(ActionMailer::Base).to respond_to(:db_settings=)
    end

    it 'adds db delivery method to available delivery methods' do
      expect(ActionMailer::Base.delivery_methods).to include(:db)
    end
  end

  # ============================================================================

  describe 'delivering' do
    before :each do
      # configure delivery method
      ActionMailer::Base.db_settings = {
        :factory => factory
      }
      ActionMailer::Base.delivery_method = :db
    end

    it 'delivers e-mail through factory' do
      mail.deliver

      expect(factory).to have_received(:create!).with(
        :from => "someone@somewhere.com",
        :to => "foo@bar.com",
        :subject => "hey",
        :content => mail.encoded
      )
    end

    it 'creates extra record for each recipient' do
      # add recipients to the example
      mail.to << "radek@paviensky.com"

      mail.deliver

      expect(factory).to have_received(:create!).with(
        :from => "someone@somewhere.com",
        :to => "foo@bar.com",
        :subject => "hey",
        :content => mail.encoded
      )

      expect(factory).to have_received(:create!).with(
        :from => "someone@somewhere.com",
        :to => "radek@paviensky.com",
        :subject => "hey",
        :content => mail.encoded
      )
    end

    it 'creates extra record for each sender' do
      # add sender to the example
      mail.from << "radek@paviensky.com"

      mail.deliver

      expect(factory).to have_received(:create!).with(
        :from => "someone@somewhere.com",
        :to => "foo@bar.com",
        :subject => "hey",
        :content => mail.encoded
      )

      expect(factory).to have_received(:create!).with(
        :from => "radek@paviensky.com",
        :to => "foo@bar.com",
        :subject => "hey",
        :content => mail.encoded
      )
    end
  end

  # ============================================================================

  describe 'error handling' do
    before :each do
      ActionMailer::Base.db_settings = {
        :factory => factory
      }
      ActionMailer::Base.deliveries.clear
      ActionMailer::Base.raise_delivery_errors = true
    end

    it 'spectacularly fails when factory is not specified' do
      ActionMailer::Base.db_settings = {
      }
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end

    it 'spectacularly fails when factory is not a valid class' do
      ActionMailer::Base.db_settings = {
        :factory => "FooBar"
      }
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end

    it 'silently fails without factory when raising errors is suppressed' do
      ActionMailer::Base.raise_delivery_errors = false
      ActionMailer::Base.db_settings = {
      }
      mail.deliver
    end

    it 'silently fails when factory is not valid class and raising errors is suppressed' do
      ActionMailer::Base.raise_delivery_errors = false
      ActionMailer::Base.db_settings = {
        :factory => "FooBar"
      }
      mail.deliver
    end

    it 'fails when there is no recipient' do
      mail.to = ""
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end

    it 'fails when there is no sender' do
      mail.from = ""
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end

    it 'fails when sender is invalid e-mail address' do
      mail.from = "Foo Bar <foo@bar / bar@bar.com>"
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end

    it 'fails when receiver is invalid e-mail address' do
      mail.to = "Foo Bar <foo@bar / bar@bar.com>"
      expect {
        mail.deliver
      }.to raise_error(ArgumentError)
    end
  end

  # ============================================================================

  describe 'chaining' do
    it 'chains delivery to configured delivery method' do
      ActionMailer::Base.db_settings = {
        :factory => factory,
        :chain_delivery_method => :test
      }
      ActionMailer::Base.deliveries.clear

      mail.deliver

      # check that e-mail was persisted
      expect(factory).to have_received(:create!).once

      # check that e-mail was chained
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end
  end

  # ============================================================================

  describe 'filtering' do
    before :each do
      ActionMailer::Base.db_settings = {
        :factory => factory,
        :chain_delivery_method => :test
      }
      ActionMailer::Base.deliveries.clear
    end

    it 'chains delivery to configured delivery method if it pass through filter' do
      ActionMailer::Base.db_settings[:chain_filter] = Proc.new {true}
      mail.deliver

      # check that e-mail was persisted
      expect(factory).to have_received(:create!).once

      # check that e-mail was chained
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it 'does not chain delivery if it does not pass through filter' do
      ActionMailer::Base.db_settings[:chain_filter] = Proc.new {false}
      mail.deliver

      # check that e-mail was persisted
      expect(factory).to have_received(:create!).once

      # check that e-mail was chained
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'pass e-mail to be delivered to the filter' do
      has_been_called = false
      ActionMailer::Base.db_settings[:chain_filter] = lambda {|m|
        expect(m).to be(mail)
        has_been_called = true
        false
      }
      mail.deliver

      expect(has_been_called).to be(true)
    end
  end
end
