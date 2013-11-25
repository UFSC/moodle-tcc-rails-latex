class TexDistro
  def self.run_command(path, command)
    log_file = 'input.log'

    Process.waitpid(
        fork do
          begin
            Dir.chdir path
            STDOUT.reopen(log_file, 'a')
            STDERR.reopen(STDOUT)

            exec command
          rescue
            File.open(log_file, 'a') { |io| io.write("#{$!.message}:\n#{$!.backtrace.join("\n")}\n") }
          ensure
            Process.exit! 1
          end
        end)
  end

  def self.command
    raise 'You forgot to define #command for your TexDistro class'
  end

  def self.pdf_command
    raise 'You forgot to define #pdf_command for your TexDistro class'
  end

  def self.default_arguments
    raise 'You forgot to define #default_arguments for your TexDistro class'
  end

  def self.build_command(arguments, filename)
    raise 'You forgot to define #build_command for your TexDistro class'
  end
end