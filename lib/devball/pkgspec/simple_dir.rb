module DevBall
	module PkgSpec
		class SimpleDir < Base
			def step_extract()
				system("cp", "-r", ball_file_name, build_dir_name) || raise(ExtractFailed, "Failed to copy ball into build.")
			end
		end
	end
end