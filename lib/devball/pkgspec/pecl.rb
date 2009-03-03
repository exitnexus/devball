module DevBall
	module PkgSpec
		class Pecl < Base
			depends_on "Php"
	
			def step_extract()
			end
	
			def step_configure()
				# pecl is all three steps in one at install time.
			end
	
			def step_build()
				# gems is all three steps in one at install time.
			end
	
			def step_install()
				Dir.chdir("packages") {|dir|
					if(!system("pecl", "install", ball()))
						raise(InstallFailed, "Could not install pecl package: #{$?}")
					end
					if(!system("pecl", "list-files", "apc")) # pecl install doesn't seem to always return an error code if it fails, so double check
						raise(InstallFailed, "Could not install pecl package: #{$?}")
					end
				}
				return ["Php"]
			end
	
			def step_uninstall()
				system("pecl", "uninstall", ball())
				super()
			end
		end
	end
end