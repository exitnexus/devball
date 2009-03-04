require 'optparse'
require 'yaml'
require 'devball/pkgspec/base'

module DevBall
	# Loads all the config options relevant to all devball commands. Yields
	# an optparse object for the specific command to add options to.
	def self.configure(argv = ARGV)
		$install_base = nil

		opts = OptionParser.new do |opts|
			opts.banner = "Usage: #{$0} [options] package_dir"
		
			opts.on_tail("-h", "--help", "Show help screen") do
				puts opts
				exit(0)
			end
			
			yield opts
		end
		
		opts.parse! argv
		
		$package_dir = ARGV.shift || raise(ArgumentError, "No package bundle directory named.")
		$package_name = File.basename($package_dir)

		$config = {}
		if (File.exists? "#{$package_dir}/config.yaml")
			$config = YAML.load_file("#{$package_dir}/config.yaml")
			$package_name = $config[:package_name] || $package_name
		end

		$install_base = "/#{$package_name}"
	end
end