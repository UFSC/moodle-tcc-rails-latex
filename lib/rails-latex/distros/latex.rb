class Latex < TexDistro
  def self.command
    'latex'
  end

  def self.pdf_command
    'pdflatex'
  end

  def self.default_arguments
    %W[-shell-escape -interaction batchmode]
  end

  def self.build_command(arguments, filename)
    default_arguments = self.default_arguments.prepend('-draftmode')
    "#{self.command} #{arguments.join(' ')} #{default_arguments.join(' ')} #{filename}.tex"
  end

  def self.build_pdf_command(arguments, filename)
    "#{self.pdf_command} #{arguments.join(' ')} #{default_arguments.join(' ')} #{filename}.tex"
  end
end