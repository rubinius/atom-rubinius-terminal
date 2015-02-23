module Rubinius
  class AtomTerminal
    include Rubinius::FFI
    extend Library

    NULL = Pointer::NULL
    MAX_READ_SIZE = 80

    attach_function :openpty, [:pointer, :pointer, :pointer, :pointer, :pointer], :int

    attr_reader :log

    def initialize(command=ENV["SHELL"] || "/bin/sh", size="80x40")
      @command = command
      @size = size
      @log = Rubinius::Logger.new "atom-terminal"
    end

    def start
      local_ptr = MemoryPointer.new :int
      remote_ptr = MemoryPointer.new :int

      status = openpty local_ptr, remote_ptr, NULL, NULL, NULL
      Errno.handle unless status == 0

      localfd = local_ptr.read_int
      remotefd = remote_ptr.read_int

      @local = IO.new localfd, File::RDWR | File::NOCTTY
      @local.sync = true

      pid = fork do
        @local.close

        Process.setsid

        remote = IO.new remotefd, File::RDWR
        remote.sync = true
        remote.close_on_exec = false

        Platform::POSIX.dup2 remotefd, STDIN.fileno
        Platform::POSIX.dup2 remotefd, STDOUT.fileno
        Platform::POSIX.dup2 remotefd, STDERR.fileno

        remote.close

        exec @command
      end

      process_session

      Process.waitpid pid
    end

    def process_session
      begin
        loop do
          read, _, error = IO.select [STDIN, @local]

          if error and not error.empty?
            log.error "select: error: #{error.inspect}"
            break
          end

          next unless read

          if read.include? STDIN
            begin
              input = STDIN.read_nonblock MAX_READ_SIZE
              break unless input
              log.info "writing to local: #{input.inspect}"
              @local.write input
            rescue IO::WaitReadable
              # do nothing
            rescue EOFError
              break
            end
          end

          if read.include? @local
            begin
              output = @local.read_nonblock MAX_READ_SIZE
              log.info "reading from local: #{output.inspect}"
              STDOUT.write output
            rescue IO::WaitReadable
              # do nothing
            rescue EOFError
              break
            end
          end
        end
      rescue => e
        log.error "#{e.class.name}: #{e.message}"
        e.backtrace.each { |f| log.error f }
        break
      ensure
        @local.close unless @local.closed?
      end
    end
  end
end

Rubinius::AtomTerminal.new(*ARGV).start
