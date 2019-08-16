require "slim"
require "attr_encrypted"

module Meetalender
  class Engine < ::Rails::Engine
    isolate_namespace Meetalender
  end
end
