require 'ftools'

module DevBall
	module PkgSpec
		class Djb < Tarball
			def extract_dir_name()
				return build_dir_name
			end
			def package_build_dir_name()
				return extract_dir_name + "/#{type}/#{ball_version}"
			end
	
			# use this to set the type of the package in djb's world (ie. admin)
			def self.set_type(type)
				@type = type
			end
			def self.type()
				return @type
			end
			def type()
				return self.class.type
			end
	
			def step_configure()
				# look for makefiles and turn off -static flags in them. (ugh)
				if (RUBY_PLATFORM =~ /darwin/)
					Dir[package_build_dir_name() + "/**/Makefile"].each {|makefile|
						File.rename(makefile, makefile + ".old")
						File.open(makefile + ".old", "r") {|fin|
							File.open(makefile, "w") {|fout|
								fin.each {|line|
									fout.puts(line.gsub(/\-static/, ''))
								}
							}
						}
					}
				end
			end
	
			def step_build()
				Dir.chdir(package_build_dir_name()) {|dir|
					# build source
					system("package/compile") || raise(BuildFailed, "Build of djb package failed: #{$?}")
					# build man pages
					Dir.chdir("man") {|dir|
						Dir["*.?"].each {|manfile|
							system("gzip", manfile)
						}
					}
				}
			end
	
			def step_install()
				# get commands from command/ and put them in the package install dir's bin directory
				Dir.chdir(package_build_dir_name) {|dir|
					# install the commands as specified by package/commands.
					commands = IO.readlines("package/commands")
					FileUtils.mkdir_p(package_install_dir + "/bin")
					commands.each {|command|
						FileUtils.copy("compile/" + command.chomp, package_install_dir + "/bin")
					}
					# install the man pages
					Dir["man/*.?.gz"].each {|manpage|
						mantype = /(.+)\.([0-8])\.gz/.match(manpage)
						FileUtils.mkdir_p(package_install_dir + "/man/man#{mantype[2]}")
						FileUtils.copy(manpage, package_install_dir + "/man/man#{mantype[2]}")
					}
				}
				return []
			end
		end
	end
end