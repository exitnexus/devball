module DevBall
	module PkgSpec
		class Tarball < Base
			# overload if this package is known to extract in a funny way (ie. no top level directory included).
			# default is to extract directly in the build directory.
			def extract_dir_name()
				File.dirname(build_dir_name)
			end
	
			def step_extract()
				# figure out what type of ball it is:
				ext = ball_file_name.match(/(\.tar|\.tar\.gz|\.tgz|\.tar\.bz2)$/)
				if (!ext)
					raise ExtractFailed, "Could not determine type of tarball."
				end
				ext = ext[1]
				args = "xvf"
				case ext
				when ".tar.gz", ".tgz":
					args = "z" + args
				when ".tar.bz2"
					args = "j" + args
				end
		
				wd = Dir.getwd
				FileUtils.mkdir_p(extract_dir_name)
				Dir.chdir(extract_dir_name) {|dir|
					system("tar", "-#{args}", "#{wd}/#{ball_file_name}") || raise(ExtractFailed, "Could not extract tarball, error #{$?}")
				}
			end
		end
	end
end