include Rake::DSL if defined?(Rake::DSL)

namespace 'coffee' do
  task "compile", [:flags] do |t,args|
    package_json = JSON.parse(File.read("package.json"))

    `coffee --compile -j #{package_json["name"]} #{args[:flags]} --output dist/ src/`

    #swap out the version
    file_name = File.join("dist","#{package_json["name"]}.js")
    filtered = File.read(file_name).gsub(/@@VERSION@@/, package_json["version"])
    File.open(file_name, "w") {|file| file.puts filtered}
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