class TexDistro
  def self.run_command(path, command, config)
    log_file = 'input.log'

    Process.waitpid(
        fork do
          begin
            if config[:dockerImage].blank?
              Dir.chdir path
            end
            # Passenger 4.0.x redirects STDOUT to STDER
            # more info: https://github.com/jacott/rails-latex/issues/29
            if defined?(::PhusionPassenger)
              STDERR.reopen(log_file, 'a')
            else
              STDOUT.reopen(log_file, 'a')
              STDERR.reopen(STDOUT)
            end

            if config[:dockerImage].present?
              picturesPath =  ''
              if config[:appPath].present?
                appPath = File.join(config[:appPath], 'public/uploads')
                picturesPath = " -v #{appPath}:#{appPath}"
              end
              exec "docker run --rm -i --user=\"$(id -un):$(id -gn)\" --net=none #{picturesPath} -v #{path}:/data #{config[:dockerImage]} /bin/bash -c \"source /etc/environment && #{command}\""
            else
              exec command
            end
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
