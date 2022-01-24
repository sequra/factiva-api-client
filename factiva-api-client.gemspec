# frozen_string_literal: true

require_relative "lib/factiva/version"

Gem::Specification.new do |spec|
  spec.name = "factiva-api-client"
  spec.version = Factiva::VERSION
  spec.authors = ["Sergio Infantes"]
  spec.email = ["sergio.infantes@sequra.es"]

  spec.summary = "Factiva API Client"
  spec.description = "Integration with Factiva API that allows to perform seaches and retrieve profiles information"
  spec.homepage = "https://github.com/sequra/factiva-api-client"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sequra/factiva-api-client"
  spec.metadata["changelog_uri"] = "https://github.com/sequra/factiva-api-client/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  spec.add_dependency "http", "~> 5.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
