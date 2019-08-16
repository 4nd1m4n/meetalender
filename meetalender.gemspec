$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "meetalender/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "meetalender"
  spec.version     = Meetalender::VERSION
  spec.authors     = ["Andreas Schau"]
  spec.email       = ["andreas.schau@hicknhack-software.com"]
  spec.homepage    = "https://www.hicknhack-software.com/"
  spec.summary     = "To have a section on a website that allows gathering of meetup groups. So that their events can regularely be syncronized into a google calendar."
  spec.description = "This gem prensents all the needed functionality to search for relevant groups on meetup, remember the chosen ones and offers a task that can be called regularely to transcribe the meetup-groups events to a google calendar. TLDR: It allows the user to subscribe to meetup-groups events."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency 'rails', '~> 5.2.2'

  # httpclient for manual auth calls
  spec.add_dependency 'httpclient', '~> 2.8', '>= 2.8.3'

  # google api for calendar event insetion
  spec.add_dependency 'google-api-client', '~> 0.30.3'

  # helps encrypt and decrypt tokens from the database
  spec.add_dependency 'attr_encrypted', '~> 3.1'

  # Asset processors
  spec.add_dependency 'slim', '~> 4.0', '>= 4.0.1'
  spec.add_dependency 'multi_json', '~> 1.13', '>= 1.13.1'


  # development dependencies
  spec.add_development_dependency "sqlite3", '~> 1.3.6'
  spec.add_development_dependency 'rspec-rails', '~> 3.8', '>= 3.8.0'
end
