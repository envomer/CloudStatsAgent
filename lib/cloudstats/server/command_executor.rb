require 'timeout'

module CloudStats
  # Runs child processes with timeout
  class CommandExecutor
    attr_reader :stdout, :stderr, :exit_code, :fulfilled
    attr_accessor :timeout
    attr_reader :pid

    def initialize(options = {})
      @timeout = options[:timeout] || 10

      @stdout = ''
      @stderr = ''
      @exit_code = -1
      @fulfilled = false
    end

    def execute!(command)
      rout, wout = IO.pipe
      rerr, werr = IO.pipe

      spawn(command, wout, werr)

      wout.close
      werr.close

      @stdout = rout.readlines.join("\n")
      @stderr = rerr.readlines.join("\n")

      rout.close
      rerr.close
    end

    private

    def spawn(command, wout, werr)
      @exit_code = -1
      @fulfilled = false
      @pid = Process.spawn(command, out: wout, err: werr)

      Timeout.timeout(timeout) do
        _, code = Process.wait2(pid)
        @exit_code = code.to_i
        @fulfilled = true
      end
    rescue
      Process.kill('KILL', @pid)
      @fulfilled = false
    end
  end
end
