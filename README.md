# DbMailer

[![Build Status](https://travis-ci.org/paviensky/db_mailer.png?branch=master)](https://travis-ci.org/paviensky/db_mailer)
[![Code Climate](https://codeclimate.com/github/paviensky/db_mailer.png)](https://codeclimate.com/github/paviensky/db_mailer)

This gem allows you to save e-mails into the database instead of sending them. This
is quite handy in dev/staging environments when you really don't want to send
real e-mails to real people but still you (or your QA) want to know what's
happening.

Another possibility is saving e-mail into the database and also sending it. This
mechanism is called "chaining" and it's described down in the README. This can
be useful for production environment when you want to persist your e-mails for
logging purposes.

## Installation

Add this line to your application's Gemfile:

    gem 'db_mailer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db_mailer

## Usage

Add to your your Rails environment configuration:

```ruby
# config/environments/development.rb <- for example

# set db delivery method as the delivery method
config.action_mailer.delivery_method = :db

# configure db delivery method
config.action_mailer.db_settings = {
  # configuration goes here
}
```

Configuration hash is described in the following chapters.

### Factory

This gem doesn't address one particular persistent mechanism like ActiveRecord.
The only interface it uses is `create!` method on a configured factory class.

```ruby
config.action_mailer.db_settings = {
  :factory => "Email"
}
```

This configuration parameter is **mandatory** and has to be specified.

When an e-mail is about to be sent then the `create!` method will be invoked
with following hash:

```ruby
{
  :from    => "foo@bar.com",
  :to      => "bar@foo.com",
  :subject => "Message subject",
  :content => "encoded-email"
}
```

By a sheer coincidence ActiveRecord has exactly this interface implemented. And
it's same with MongoMapper and maybe others.

So if the "Email" from the code above is AR model then it'll work out of the box.
But remember that you are not limited to that as Email can look like this:

```ruby
class Email
  def self.create!(params)
    puts params[:from]
  end
end
```

### Chaining

The very useful part of the gem behaviour is the ability to pass e-mail for
further delivery. It means that you can record your e-mails into the database
**and** deliver them with selected delivery method.

Let's start with an example:

```ruby
# makes :db primary delivery method
config.action_mailer.delivery_method = :db

# configuration of DB delivery method
config.action_mailer.db_settings = {
  :factory => "Email",
  :chain_delivery_method => :smtp
}

# smtp delivery method settings
config.action_mailer.smtp_settings = {
  # standard SMTP configuration...
}
```

If we take the configuration above then sending e-mail would mean that it's
persisted through Email model (that's nothing new at this moment) but the new
thing is that after it's persisted it will be send with SMTP delivery method.

You set the same delivery method (:smtp, :file, :sendmail, :test) to the
`:chain_delivery_method` as you normally set on `#delivery_method`.

The "chained" delivery method is to be configured in a same way as if it is
used as a primary delivery method. See Rails documentation for more information
on that.

### Filtered chaining

The last option to configure is `:chain_filter` which expects proc. This proc
is evaluated before chaining and the chained delivery happens only if returns
some "truthy" value.

Example:

```ruby
# makes :db primary delivery method
config.action_mailer.delivery_method = :db

# configuration of DB delivery method
config.action_mailer.db_settings = {
  :factory => "Email",
  :chain_delivery_method => :file
  # chain only e-mail with the "subscription" subject
  :chain_filter => Proc.new({|mail|
    mail.subject =~ /subscription/
  })
}
```

## Contributing

1. Fork it ( https://github.com/paviensky/db_mailer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
