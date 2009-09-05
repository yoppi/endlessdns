$LOAD_PATH.unshift File.dirname(__FILE__) + "/lib"

require 'rake'
require 'rake/clean'
require 'endlessdns/version'

desc "default task"
task :default => [:install]

name = 'endlessdns'
version = EndlessDNS::VERSION

spec = Gem::Specification.new do |s|
  s.name = name
  s.summary = "Enhanced Local DNS cache server."
  s.description = "EndlessDNS provide persistentcy DNS cache system."
  s.files = %w{README Rakefile} + Dir["lib/**/*.rb"]
  s.executables = %{endlessdns}
  s.add_dependency("ahobson-pcap", ">= 0.0.7")
  s.add_dependency("net-dns", ">= 0.5.3")
  s.authors = %{yoppi}
  s.email = "y.hirokazu@gmail.com"
end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true
end

task :gemspec do
  filename = "#{name}.gemspec"
  open(filename, 'w') do |f|
    f.write spec.to_ruby
  end
  puts <<-EOS
  Successfully generated gemspec
  Name: #{name}
  Version: #{version}
  File: #{filename}
  EOS
end

desk "install task"
task :install => [:package] do 
  sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

desk "uninstall task"
task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{name}}
end

CLEAN.include ['pkg']
