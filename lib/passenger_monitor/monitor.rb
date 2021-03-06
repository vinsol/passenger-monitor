module PassengerMonitor
  class Monitor
    # Default allowed memory limit for a passenger worker (MB)
    DEFAULT_MEMORY_LIMIT = 150 # in MB
    # Default log file name
    DEFAULT_LOG_FILE = 'passenger_monitoring.log'
    # default waiting time after graceful kill attempt to kill process forcefully
    DEFAULT_WAIT_TIME = 10 # in Seconds
    # Passenger Process Name Regex
    DEFAULT_PROCESS_NAME_REGEX = /Passenger RubyApp:/

    # Initialize the service and apply a check on all passenger processes
    # given `configurations` (defaults to `{}`)
    #
    # == Parameters:
    # config::
    #   Hash which includes the configurations keys i.e.
    #     1. :memory_limit - allowed memory limit for a passenger worker
    #     2. :log_file - the name of the log file
    #     3. :wait_time - the time to wait to kill the worker forcefully
    #     4. :process_name_regex - regex for the passenger worker of the application
    #
    def self.run(config = {})
      new(config).check
    end

    # Sets memory limit, log file, wait time, process name regex and logger
    #
    def initialize(params = {})
      params = params.to_hash
      @memory_limit = fetch_memory_limit(params)
      @log_file = fetch_log_file(params)
      @wait_time = fetch_wait_time(params)
      @process_name_regex = fetch_process_name_regex(params)
      @logger = Logger.new(@log_file)
    end

    # Checks memory of all the passenger processes and for bloadted workers
    # it creates thread for each to kill it.
    #
    def check
      @logger.info 'Checking bloated Passenger workers'

      threads = []

      passenger_workers_details.each_line do |line|
        next unless (line =~ @process_name_regex)

        pid, memory_usage =  extract_stats(line)

        # If a given passenger process is bloated try to
        # kill it gracefully and if it fails, force killing it
        if bloated?(pid, memory_usage)
          threads << Thread.new { self.handle_bloated_process(pid) }
        end
      end

      threads.map(&:join)
      @logger.info 'Finished checking for bloated Passenger workers'
    end

    # Handles bloated processes:
    #
    #   1. Kill it gracefully
    #   2. Wait for the given time
    #   3. if it still exists then kill it forcefully.
    #
    # == Parameters:
    # pid::
    #   Process ID.
    #
    def handle_bloated_process(pid)
      kill(pid)
      wait
      kill!(pid) if process_running?(pid)
    end

    private

    def fetch_memory_limit(params)
      params.key?(:memory_limit) ? params[:memory_limit].to_f : DEFAULT_MEMORY_LIMIT
    end

    def fetch_log_file(params)
      params.key?(:log_file) ? params[:log_file] : DEFAULT_LOG_FILE
    end

    def fetch_wait_time(params)
      params.key?(:wait_time) ? params[:wait_time].to_i : DEFAULT_WAIT_TIME
    end

    def fetch_process_name_regex(params)
      if params.key?(:process_name_regex)
        Regexp.new(params[:process_name_regex].to_s)
      else
        DEFAULT_PROCESS_NAME_REGEX
      end
    end

    # Fetches the stats of passenger-memory-stats from system.
    # Using `env -i` to remove surrounding environment of bundle.
    def passenger_workers_details
      passenger_memory_status_path = `env -i which passenger-memory-stats`
      `env -i #{ passenger_memory_status_path }`
    end

    # Checks if a given process is still running
    # == Parameters:
    # pid::
    #   Process ID.
    #
    def process_running?(pid)
      Process.getpgid(pid) != -1
    rescue Errno::ESRCH
      false
    end

    # Wait for process to be killed
    def wait
      @logger.error "Waiting for worker to shutdown..."
      sleep(DEFAULT_WAIT_TIME)
    end

    # Kill it gracefully
    def kill(pid)
      @logger.error "Trying to kill #{pid} gracefully..."
      Process.kill("SIGUSR1", pid)
    end

    # Kill it forcefully
    def kill!(pid)
      @logger.fatal "Force kill: #{pid}"
      Process.kill("TERM", pid)
    end

    # Extracts pid and memory usage of a single Passenger worker
    def extract_stats(line)
      stats = line.split
      return stats[0].to_i, stats[3].to_f
    end

    # Check if a given process is exceeding memory limit
    def bloated?(pid, size)
      bloated = size > @memory_limit
      @logger.error "Found bloated worker: #{pid} - #{size}MB" if bloated
      bloated
    end
  end
end