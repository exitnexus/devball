require 'rubygems'
require 'rake/gempackagetask'

GEM_VERSION = ENV['GEM_VERSION'] || `git describe`.gsub(/-([0-9]+)-[a-z0-9]+$/, '.\1')

spec = Gem::Specification.new do |s|
    s.name       = "devball"
    s.version    = GEM_VERSION
    s.author     = "Graham Batty"
    s.email      = "graham at nexopia dot com"
    s.homepage   = "http://github.com/nexopia/devball"
    s.platform   = Gem::Platform::RUBY
		s.rubyforge_project  = "nexopia"
    s.summary    = "A tool for building a self-contained set of packages that can be portably be moved from one binary-compatible machine to another."
    s.files      = FileList["{bin,lib}/**/*"].exclude("rdoc").to_a
		s.executables = ["devball", "devball-build", "devball-pull", "devball-push"]
    s.require_path      = "lib"
    s.has_rdoc          = true
    s.extra_rdoc_files  = ['README']
end

Rake::GemPackageTask.new(spec) do |pkg|
end

desc "Publish the release files to RubyForge."
task :release => [ :package ] do
  require 'rubyforge'
  require 'rake/contrib/rubyforgepublisher'
 
  packages = %w( gem ).collect{ |ext| "pkg/devball-#{GEM_VERSION}.#{ext}" }
 
	begin
	  rubyforge = RubyForge.new
	  rubyforge.login
	  rubyforge.add_release('nexopia', 'devball', "devball-#{GEM_VERSION}", *packages)
	rescue
		puts("Error trying to push gem. Did you run rubyforge setup and/or rubyforge login?")
		raise
	end
end