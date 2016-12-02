namespace :passenger do
  desc "monitors passenger workers and kill bloated ones"
  task :monitor, [:memory_limit, :log_file, :wait_time, :process_name_regex] do |t, args|
    PassengerMonitor::Monitor.run args
  end
end