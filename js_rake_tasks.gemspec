Gem::Specification.new do |s|
  s.name               = "js_rake_tasks"
  s.version            = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Justin Searls"]
  s.date = %q{2011-02-05}
  s.description = %q{Rake tasks for little JavaScript projects}
  s.email = %q{searls@gmail.com}
  s.files = ["lib/js_rake_tasks.rb"]
  s.homepage = %q{http://github.com/searls/js_rake_tasks}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Provides a few tasks for managing CoffeeScript/JavaScript projects}

  s.add_dependency 'json_pure', '~> 1.6.1'
  s.add_dependency 'semver', '~> 1.0.1'
  s.add_dependency 'git', '~> 1.2.5'
end

