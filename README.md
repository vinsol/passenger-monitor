# PassengerMonitor

This gem monitors passenger workers of your application and if the workers exceed the memory limit then it kills them (first gracefully, waits and then forcefully). It fetches the memory of the passenger workers from the system command `passenger-memory-stats`, checks the memory of each worker **concurrently (using threads)** and kills them if it finds them bloated. First, it kills the process gracefully and wait for it to die, if the process still appears then it kills it forcefully

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'passenger-monitor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install passenger-monitor

## Usage

The gem provides a service class which can be initialized to check the passenger workers.

```ruby
PassengerMonitor.run({:memory_limit=>"150",
                      :log_file=>"passenger_config.log",
                      :wait_time=>"15",
                      :process_name_regex=>"passenger"})
```

**Parameters options:**
1. **:memory_limit**: allowed memory limit for a passenger worker
2. **:log_file**: the name of the log file
3. **:wait_time**: the time to wait to kill the worker forcefully
4. **:process_name_regex**: regex for the passenger worker of the application

### Use Rake task
It also provides a rake task which can be scheduled in cron tasks. To load tasks add following lines in your `Rakefile`:

```ruby
spec = Gem::Specification.find_by_name 'passenger_monitor'
Dir.glob("#{spec.gem_dir}/lib/tasks/*.rake").each { |task_file| load task_file }
```
Now rake task `passenger:monitor` will be available. For custom configuration, send arguments in task in following order: `:memory_limit, :log_file, :wait_time, :process_name_regex`:

```system
bundle exec rake passenger:monitor[150,"passenger_config.log",15,"Passenger RubyApp"]
```

That's it, now never think of bloated passengers.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/passenger-monitor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License