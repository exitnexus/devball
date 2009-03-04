module DevBall
	module PkgSpec
		class Gem < Base
			if ENV['RUBINIUS']
				depends_on "Rubinius"
			elsif ENV['REE']
				depends_on "Ruby"
			else
				depends_on "RubyGems"
			end
	
			def step_extract()
				# whether the gem is a local file or fetched from rubyforge, we don't extract it.
			end
	
			def step_configure()
				# gems are all three steps in one at install time.
			end
	
			def step_build()
				# gems are all three steps in one at install time.
			end
	
			def configure_params()
				return {} # no need for prefix
			end
	
			# override to specify a different gem repository. Default returns nil and indicates to use the standard rubyforge repo.
			def gem_repository()
				return nil
			end
	
			def step_install()
				Dir.chdir($package_dir) {|dir|
					params = configure_params.collect {|key, val|
						if (val)
							"--#{key}=#{val}"
						else
							"--#{key}"
						end
					}
			
					if (params.length)
						params.unshift("--")
					end

					if (gem_repository)
						params.unshift(gem_repository)
						params.unshift("--source")
					end
			
					if (ENV['RUBINIUS'])
		#				params = ["rbx", "gem", "install", "--install-dir=/nexopia/packages/Rubinius/lib/rubinius/gems/1.8", ball, *params].collect {|i| %Q{"#{i}"} }
						params = ["rbx", "gem", "install", ball, *params].collect {|i| %Q{"#{i}"} }
					else
						params = ["gem", "install", ball, *params].collect {|i| %Q{"#{i}"} }
					end
					# and here this gets complicated, since gems don't return an error code if they fail. They just talk about it on their output.
					success = false
					errors = []
					open("|#{params.join(' ')} 2>&1", "r") {|io|
						io.each {|line|
							puts(line)
							if (match = /ERROR:\s+(.+)$/.match(line))
								errors.push(match[1])
							end
							if (match = /^[0-9]+ gems? installed/.match(line))
								success = true
							end
							if (match = /^Successfully installed/.match(line))
								success = true
							end
						}
					}
					if (!success)
						raise(InstallFailed, "Could not install gem: #{errors.join(', ')}")
					end
				}
				if (ENV['JRUBY'])
					return "JRuby"
				elsif (ENV['Rubinius'])
					return "Rubinius"
				else
					return "Ruby"
				end
			end
	
			def step_uninstall()
				if (ENV['RUBINIUS'])
					system("rbx", "gem", "uninstall", ball())
				else
					system("gem", "uninstall", ball())
				end
				super()
			end
		end
	end
end