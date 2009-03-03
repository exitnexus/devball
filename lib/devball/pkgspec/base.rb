# defines a bunch of helper functions as well as the main steps for building a package
# These steps are:
# - step_extract
# - step_patch
# - step_environment_setup
# - step_configure
# - step_build
# - step_install
# - step_setup_links
# There are also two that are involved in removing the resulting files.
# - remove_build
# - remove_install
# Derived classes should also describe their dependency tree through the
# PkgSpec.depends_on function.
require 'fileutils'
module DevBall
	module PkgSpec
		class Error < Exception; end
		class Undefined < Error; end
		class PackageLoadError < Error; end
		class ExtractFailed < Error; end
		class ConfigureFailed < Error; end
		class BuildFailed < Error; end
		class InstallFailed < Error; end
		class RemoveFailed < Error; end
		
		# Autoload arbitrary devball pkgspec-types through const_missing
		def self.const_missing(name)
			autoloading = (Thread.current[:autoloading] ||= {})
			if (autoloading[name])
				raise NameError, "uninitialized constant DevBall::PkgSpec::#{name} (autoload already tried to find it)"
			end
			autoloading[name] = true
			
			begin
				filename = name.to_s.gsub(/^[A-Z]/) {|a| a.downcase }.gsub(/[A-Z]/) {|a| "_#{a.downcase}" }
				require 'devball/pkgspec/' + filename
				if (!const_defined?(name))
					raise NameError, "uninitialized constant DevBall::PkgSpec::#{name} (autoload found file but file did not define class)"
				end
				return const_get(name)
			rescue LoadError
				raise NameError, "uninitialized constant DevBall::PkgSpec::#{name} (autoload failed to find matching file)"				
			ensure
				autoloading[name] = false
			end
		end

		class Base
			class <<self
				def load_packages(dir, explicit, only_explicit = false)
					# load all the packagespecs
					@packages ||= {}
					@install_packages ||= {}
					Dir["#{dir}/*.pkgspec"].each {|f|
						load "#{Dir.getwd}/#{f}"
					}

					def explicit.include?(str)
						each {|i|
							if (i === str)
								return true
							end
						}
						return false
					end
			
					@packages_inorder = @install_packages.collect {|name, pkg|
						if (deps = pkg.recursive_depends_on)
							[deps, name].flatten
						else
							name
						end
					}.flatten.uniq.collect {|pkgname|
						if (!only_explicit || explicit.include?(pkgname))
							@packages[pkgname] || raise(Error, "Unknown package #{pkgname} in package list (#{@packages.keys.join(",")})")
						else
							nil
						end
					}.compact
					return @packages_inorder
				end
				attr :packages_inorder
		
				def find(name)
					@packages ||= {}
			
					return @packages[name]
				end
		
				def depends_on(*deps)
					@deps ||= []
					@deps.push(*deps) if (deps.length > 0)

					deps = []
					if (superclass && superclass.respond_to?(:depends_on))
						deps.push(*superclass.depends_on)
					end
					deps.push(*@deps)
					deps
				end

				def register_package(klass, name, required)
					@packages ||= {}
					@packages[name] = klass
					if (required)
						@install_packages ||= {}
						@install_packages[name] = klass
					end
				end
				attr :ball
				def set_ball(name, required = true)
					@ball = name
					@instance = self.new
					PkgSpec.register_package(@instance, @instance.package_name, required)
				end
				# defines it as a library that is only required if somethind depended on it.
				def set_lib_ball(name)
					set_ball(name, false)
				end
		
				attr :patches
				def set_patch(*patches)
					@patches ||= []
					@patches += patches
				end
			end
			def ball
				return self.class.ball
			end
			def depends_on		
				return self.class.depends_on
			end
			def recursive_depends_on
				return self.class.depends_on.collect {|dep|
					pkg = PkgSpec.find(dep) || raise(PackageLoadError, "Package #{to_s} depends on #{dep} which doesn't exist.")
					[pkg.recursive_depends_on, dep]
				}.flatten
			end
	
			def ball_file_name()
				return "packages/#{ball}"
			end
			# extracts the ball to the correct place in the builddir
			def step_extract()
				raise Undefined, "Behaviour undefined for extracting the ball"
			end
	
			def step_patch()
				if (File.directory?(build_dir_name) && self.class.patches && self.class.patches.length)
					orig = Dir.getwd
					Dir.chdir(build_dir_name) {|dir|
						self.class.patches.each {|patch|
							system("patch -p1 < #{orig}/packages/#{patch}") || raise(PatchFailed, "Patch #{patch} failed to apply. Errno #{$?}")
						}
					}
				end
			end
	
			# get the name of the ball without extention
			def ball_version()
				ball().gsub(/^(.*)\.(gem|tar\.gz|tgz|tar\.bz2)$/, '\1')
			end
	
			# get the name of the ball without version. Cuts off after the first hyphen
			def ball_name()
				ball_version().gsub(/^([^\-]+)$/, '\1')
			end
	
			# get the name of the subdirectory the ball was extracted to
			# provides a default implementation that uses ball() and takes off known extensions
			# on the assumption that its name will be derived from the ball name that way.
			# If that's not true, it should be overriden
			def build_dir_name()
				return "#{$build_dir}/#{ball_version}"
			end
	
			# get the name of the package without any version information. Default
			# implementation bases it on the class name.
			def package_name()
				package_name = self.class.name.to_s
				package_name = package_name.gsub(/^(.+?)(Package)?$/, '\1')
				return package_name
			end
			def to_s()
				package_name()
			end
	
			# Returns the directory the package will be installed in.
			def package_install_dir()
				return "/nexopia/packages/#{package_name}"
			end
	
			# configure options to pass to ./configure. The default step_configure function
			# uses this, but derived versions don't have to, but whatever they do should
			# have the same effect as the prefix set by the hash this returns.
			# if this is overloaded, you should merge your options with super()
			def configure_params()
				return {:prefix=>package_install_dir}
			end
	
			def step_environment_setup()
			end
	
			def configure_script_name()
				"./configure"
			end
	
			# do the configure step. The only requirement is that this end up installing things
			# in /nexopia/packages/#{package_name}. The default implementation runs ./configure in
			# the build dir with the results of configure_params.
			def step_configure()
				Dir.chdir(build_dir_name) {|dir|
					params = configure_params.collect {|key, val| 
						if (val)
							"--#{key}=#{val}" 
						else
							"--#{key}"
						end
					}
					if (!system(configure_script_name, *params))
						raise ConfigureFailed, "Configuration failed with error: #{$?}"
					end
				}
			end

			# targets for the build call to make to use
			def build_targets()
				return ["all"]
			end

			def build_concurrent?()
				return true
			end
	
			# do the build step. Default implementation is to simply run make in the build dir.
			def step_build()
				Dir.chdir(build_dir_name) {|dir|
					args = []
					args.push("-j4") if build_concurrent?
					args += build_targets
					if (!system("make", *args))
						raise BuildFailed, "Build failed with error: #{$?}"
					end
				}
			end
	
			def install_targets()
				return ["install"]
			end

			# do the install step. Default implementation is to simply run "make install" in the build dir
			def step_install()
				Dir.chdir(build_dir_name) {|dir|
					if (!system("make", *install_targets))
						raise InstallFailed, "Install failed with error: #{$?}"
					end
				}
				return []
			end
	
			# Returns any explicit filename translations that should be performed on a file when linking
			# it into the right place in the tree.
			def link_mappings()
				return {}
			end
	
			def install_service_links(base_from)
				Dir[File.join(base_from, "*")].each {|service|
					supervise_dir = File.join("/var/nexopia/supervise", File.basename(service))
					begin
						File.delete(File.join(service, "supervise"))
					rescue; end
					File.symlink(supervise_dir, File.join(service, "supervise"))
					if (File.directory?(File.join(service, "log")))
						begin
							File.delete(File.join(service, "log", "supervise"))
						rescue; end
						File.symlink("#{supervise_dir}-log", File.join(service, "log", "supervise"))
					end
				}
			end
	
			# internal implementation of setting the links up for a given directory.
			# pass nil into subdir to suppress recursion.
			def install_links(base_from, base_into, subdir)
				recurse = subdir
				subdir = "" if !subdir
				Dir[File.join(base_from, subdir, "*")].each {|file|
					stat = File.lstat(file)
					if (stat.directory? && recurse)
						FileUtils.mkdir_p(File.join(base_into, subdir, File.basename(file)))
						install_links(base_from, base_into, File.join(subdir, File.basename(file)))
					end
					if (!stat.directory?)
						target = File.join(base_into, subdir, File.basename(file))
						begin
							File.delete(target)
						rescue
						end
						File.symlink(file, target)
					end
				}
			end
	
			# Build the appropriate links for the package so it can be run properly from /nexopia
			def step_setup_links()
				install_links(package_install_dir, "/nexopia", nil)
				FileUtils.mkdir_p("/nexopia/bin")
				install_links(File.join(package_install_dir, "bin"), "/nexopia/bin", "")
				install_links(File.join(package_install_dir, "sbin"), "/nexopia/bin", "")
				install_links(File.join(package_install_dir, "libexec"), "/nexopia/bin", "")
				FileUtils.mkdir_p("/nexopia/lib")
				install_links(File.join(package_install_dir, "lib"), "/nexopia/lib", "")
				FileUtils.mkdir_p("/nexopia/include")
				install_links(File.join(package_install_dir, "include"), "/nexopia/include", "")
				FileUtils.mkdir_p("/nexopia/man")
				install_links(File.join(package_install_dir, "man"), "/nexopia/man", "")
				FileUtils.mkdir_p("/nexopia/etc")
				install_links(File.join(package_install_dir, "etc"), "/nexopia/etc", "")
		
				FileUtils.mkdir_p("/nexopia/service-privileged")
				install_service_links(File.join(package_install_dir, "service-privileged"))
				install_links(File.join(package_install_dir, "service-privileged"), "/nexopia/service-privileged", "")
				FileUtils.mkdir_p("/nexopia/service-required")
				install_service_links(File.join(package_install_dir, "service-required"))
				install_links(File.join(package_install_dir, "service-required"), "/nexopia/service-required", "")
				FileUtils.mkdir_p("/nexopia/service-optional")
				install_service_links(File.join(package_install_dir, "service-optional"))
				install_links(File.join(package_install_dir, "service-optional"), "/nexopia/service-optional", "")
			end
	
			def remove_build()
				system("rm", "-rf", build_dir_name) || raise(RemoveFailed, "Could not delete existing build directory.")
			end
	
			def remove_install()
				system("rm", "-rf", package_install_dir) || raise(RemoveFailed, "Could not delete installed directory.")
			end
		end
	end
end