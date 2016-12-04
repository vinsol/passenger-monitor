require 'spec_helper'

def stub_system_command(response = '')
  response = !response.empty? ? response : %Q{
    25096  637.9 MB   165.4 MB  Passenger RubyApp:
    25097  637.9 MB   100.4 MB  Passenger RubyApp:
    25098  637.9 MB   120.4 MB  Passenger RubyApp:
  }

  allow_any_instance_of(PassengerMonitor::Monitor).to receive(:`).and_return(response)
end

def stub_process_status(response = -1)
  allow(Process).to receive(:getpgid).and_return(response)
end

def stub_process_kill(method_name, signal, pid)
  allow(Process).to receive(method_name).with(signal, pid)
end

def stub_wait(time = 10)
  allow_any_instance_of(PassengerMonitor::Monitor).to receive(:sleep).with(time)
end

describe PassengerMonitor::Monitor do
  let(:params) { {
    :memory_limit=>"200",
    :log_file=>"passenger_monitor.log",
    :wait_time=>"15",
    :process_name_regex=>"passenger"}}

  let(:object_with_params) { PassengerMonitor::Monitor.new(params) }
  let(:object_without_params) { PassengerMonitor::Monitor.new }

  describe 'Constants' do
    it 'PassengerMonitor::Monitor::DEFAULT_MEMORY_LIMIT => 150' do
      expect(PassengerMonitor::Monitor::DEFAULT_MEMORY_LIMIT).to eq(150)
    end
    it "PassengerMonitor::Monitor::DEFAULT_LOG_FILE => 'passenger_monitoring.log'" do
      expect(PassengerMonitor::Monitor::DEFAULT_LOG_FILE).to eq('passenger_monitoring.log')
    end
    it 'PassengerMonitor::Monitor::DEFAULT_WAIT_TIME => 10' do
      expect(PassengerMonitor::Monitor::DEFAULT_WAIT_TIME).to eq(10)
    end
    it 'PassengerMonitor::Monitor::DEFAULT_PROCESS_NAME_REGEX => /Passenger RubyApp:/' do
      expect(PassengerMonitor::Monitor::DEFAULT_PROCESS_NAME_REGEX).to eq(/Passenger RubyApp:/)
    end
  end

  describe 'Parameters' do
    before do
      stub_system_command
    end

    context 'when params are not provided' do
      it 'picks up default configurations' do
        expect(object_without_params.instance_variable_get(:@memory_limit)).to eq(150)
        expect(object_without_params.instance_variable_get(:@log_file)).to eq('passenger_monitoring.log')
        expect(object_without_params.instance_variable_get(:@wait_time)).to eq(10)
        expect(object_without_params.instance_variable_get(:@process_name_regex)).to eq(/Passenger RubyApp:/)
      end
    end

    context 'when params are provided' do
      it 'picks up custom params' do
        expect(object_with_params.instance_variable_get(:@memory_limit)).to eq(200)
        expect(object_with_params.instance_variable_get(:@log_file)).to eq('passenger_monitor.log')
        expect(object_with_params.instance_variable_get(:@wait_time)).to eq(15)
        expect(object_with_params.instance_variable_get(:@process_name_regex)).to eq(/passenger/)
      end
    end
  end

  describe 'passenger workers' do
    after do
      PassengerMonitor::Monitor.run
    end

    context 'when workers are bloated' do
      before do
        stub_system_command
        stub_process_kill(:kill, 'SIGUSR1', 25096)
        stub_process_status
        stub_wait
      end

      it 'tries to kill them gracefully' do
        expect(Process).to receive(:kill).with('SIGUSR1', 25096)
      end

      it 'waits for the workers to get killed' do
        expect_any_instance_of(PassengerMonitor::Monitor).to receive(:sleep).with(10)
      end

      context 'when workers are killed gracefully' do
        it 'doesn\'t try to kill them forcefully' do
          expect(Process).not_to receive(:kill).with('TERM', 25096)
        end
      end

      context 'when workers are not killed gracefully' do
        before do
          stub_process_status(1)
        end

        it 'tries to kill them forcefully' do
          expect(Process).to receive(:kill).with('TERM', 25096)
        end
      end
    end

    context 'when workers are not bloated' do
      before { stub_system_command(%Q{
        25096  637.9 MB   105.4 MB  Passenger RubyApp:
        25098  637.9 MB   120.4 MB  Passenger RubyApp:
        })
      }

      it 'doesn\'t create threads' do
        expect(Thread).not_to receive(:new)
      end
    end
  end
end
