include Rake::DSL if defined?(Rake::DSL)

namespace 'coffee' do
  task "compile", [:flags] do |t,args|
    require 'json'
    require 'execjs'
    require 'coffee-script'

    source_code = FileList.new('src/**/*.coffee').map { |file_path| File.read(file_path) }.join("\n")

    package_json = JSON.parse(File.read("package.json"))
    uncompressed_output = filter_output(compile_coffee_script(source_code), package_json)
    File.open(file_name(package_json), "w") { |file| file.puts uncompressed_output }
    File.open(file_name(package_json, true), "w") { |file| file.puts uncompressed_output }
  end

  def file_name(package_json, minified = false)
    File.join("dist","#{package_json["name"]}#{minified ? "-min" : ""}.js")
  end

  def compile_coffee_script(coffee_script)
    context = ExecJS.compile(File.read(CoffeeScript::Source.bundled_path))
    context.call("CoffeeScript.compile", coffee_script, :bare => false)
  end

  def filter_output(compiled_output, package_json)
    compiled_output.gsub(/@@VERSION@@/, package_json["version"])
  end

  def uglify(uncompressed_javascript)

  end
end

namespace "js" do
  namespace "version" do
    namespace "bump" do
      task "major" do
        update_version { |v| v.major += 1 }
      end

      task "minor" do
        update_version { |v| v.minor += 1 }
      end

      task "patch" do
        update_version { |v| v.patch += 1 }
      end

      def update_version &blk
        git = VersionsGit.new
        fail("Oops! Can't bump a version with a dirty repo!") unless git.clean?
        version = update_package_json(&blk)
        Rake::Task["coffee:compile"].invoke
        tag_project(git,version)
      end

      def tag_project(git, version)
        git.tag(version)
        git.push
      end

      def update_package_json
        require 'json'
        require 'semver'

        package = JSON.parse(File.read("package.json"))
        version = SemVer.new(*package["version"].split(".").map(&:to_i))
        yield(version)
        package["version"] = version.format('%M.%m.%p%s')
        File.open('package.json', 'w') do |f|
          f.puts JSON.pretty_generate(package)
        end
        package["version"]
      end

      class VersionsGit
        def initialize
          require 'git'
          @g = Git.open(Dir.pwd)
        end

        def tag(version)
          @g.add('package.json')
          @g.commit("Bumping version to #{version}")
          @g.add_tag(version)
        end

        def push
          @g.push("origin",@g.current_branch,true)
        end

        def clean?
          [@g.status.deleted,@g.status.added,@g.status.changed].all? { |o| o.size == 0 }
        end
      end
    end

  end
end