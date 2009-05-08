require 'rubygems'
require 'rubygems/package_task'

GEM_VERSION = ENV['GEM_VERSION'] || `git describe`.gsub(/-([0-9]+)-[a-z0-9]+$/, '.\1')

spec = Gem::Specification.new do |s|
	s.name              = "devball"
	s.version           = GEM_VERSION
	s.authors           = ["Chris Thompson", "Graham Batty"]
	s.email             = "cthompson@nexopia.com"
	s.homepage          = "http://github.com/nexopia/devball"
	s.summary           = "A tool for building a self-contained set of packages that can be portably be moved from one binary-compatible machine to another."
	s.description       = "This is a tool for building a devball. A devball is a self-contained set of packages that can be portably be moved from one binary-compatible machine to another.  See README for more information."
	s.files             = FileList["{bin,lib}/**/*"]
	s.executables       = %w[devball devball-build devball-pull devball-push]
	s.has_rdoc          = true
	s.extra_rdoc_files  = %w[README CHANGELOG]
	s.rubyforge_project = "nexopia"
end

Gem::PackageTask.new(spec) do |pkg|
end

task :default => [:package]
