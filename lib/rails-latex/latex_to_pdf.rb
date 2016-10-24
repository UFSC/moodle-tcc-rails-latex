class LatexToPdf
  def self.config
    @config ||= {:distro => :latex, :arguments => ['-halt-on-error'], :bibtex => false, :dockerImage => ''}
  end

  # Converts a string of LaTeX +code+ into a binary string of PDF.
  #
  # pdflatex is used to convert the file and creates the directory +#{Rails.root}/tmp/rails-latex/+ to store intermediate
  # files.
  #
  # The config argument defaults to LatexToPdf.config but can be overridden using @latex_config.
  #
  # The parse_twice argument is deprecated in favor of using config[:parse_twice] instead.
  def self.generate_pdf(code, config)
    config = self.config.merge(config)
    tex_distro = self.tex_distro(config[:distro])

    dir=File.join(Rails.root, 'tmp', 'rails-latex', "#{Process.pid}-#{Thread.current.hash}")

    if config[:dockerImage].present?
      input = 'input'
      inputLocal = File.join(dir, 'input')
      latex_file = "#{inputLocal}.tex"
      pdf_file = "#{inputLocal}.pdf"
    else
      input = File.join(dir, 'input')
      latex_file = "#{input}.tex"
      pdf_file = "#{input}.pdf"
    end
    log_file = "#{input}.log"

    FileUtils.mkdir_p(dir)
    File.open(latex_file, 'wb') { |io| io.write(code) }

    tex_distro.run_command(dir, tex_distro.build_command(config[:arguments], input), config)

    if config[:bibtex]
      bib_file = input
      bib_index_file = "#{input}.idx"

      tex_distro.run_command(dir, "bibtex #{bib_file}", config)
      tex_distro.run_command(dir, "makeindex #{bib_index_file}", config)

      tex_distro.run_command(dir, tex_distro.build_command(config[:arguments], input), config)
      tex_distro.run_command(dir, tex_distro.build_command(config[:arguments], input), config)
    end

    # This is where PDF is actually generated
    tex_distro.run_command(dir, tex_distro.build_pdf_command(config[:arguments], input), config)


    if File.exist? pdf_file
      FileUtils.mv("#{input}.log", File.join(dir, '..', 'input.log'))
      result=File.read(pdf_file)
      FileUtils.rm_rf(dir)
    else
      raise "PDF generation failed: See #{log_file} for details"
    end
    result
  end


  # Escapes LaTex special characters in text so that they wont be interpreted as LaTex commands.
  #
  # This method will use RedCloth to do the escaping if available.
  def self.escape_latex(text)
    # :stopdoc:
    unless @latex_escaper
      if defined?(RedCloth::Formatters::LATEX)
        class << (@latex_escaper=RedCloth.new(''))
          include RedCloth::Formatters::LATEX
        end
      else
        class << (@latex_escaper=Object.new)
          ESCAPE_RE=/([{}_$&%#])|([\\^~|<>])/
          ESC_MAP={
              '\\' => 'backslash',
              '^' => 'asciicircum',
              '~' => 'asciitilde',
              '|' => 'bar',
              '<' => 'less',
              '>' => 'greater',
          }

          def latex_esc(text) # :nodoc:
            text.gsub(ESCAPE_RE) { |m|
              if $1
                "\\#{m}"
              else
                "\\text#{ESC_MAP[m]}{}"
              end
            }
          end
        end
      end
      # :startdoc:
    end

    @latex_escaper.latex_esc(text.to_s).html_safe
  end

  def self.tex_distro(name)
    case name
      when :latex
        Latex
      when :xelatex
        Xelatex
      else
        raise InvalidArgumentError, 'unknown tex distro'
    end
  end
end

