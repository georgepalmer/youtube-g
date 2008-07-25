spec = Gem::Specification.new do |s|
  s.name = 'youtube-g'
  s.version = '0.4.7'
  s.date = '2008-06-08'
  s.summary = 'An object-oriented Ruby wrapper for the YouTube GData API'
  s.email = "ruby-youtube-library@googlegroups.com"
  s.homepage = "http://youtube-g.rubyforge.org/"
  s.description = "An object-oriented Ruby wrapper for the YouTube GData API"
  s.has_rdoc = true
  s.authors = ["Shane Vitarana", "Walter Korman", "Aman Gupta", "Filip H.F. Slagter", "msp"]

  s.files = Dir['lib/**/*', 'test/**/*', 'integration-test/**/*', 'History.txt', 'Manifest.txt', 'README.txt', 'Rakefile', 'TODO.txt' ]
  puts "GEM files[#{s.files.length}]:"
  s.files.each do |file|
    puts file
  end
  s.test_files = Dir['test/**/*']
  puts "TEST files[#{s.test_files.length}]:"
  s.test_files.each do |file|
    puts file
  end
  s.rdoc_options = ["--main", "README.txt"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
end
