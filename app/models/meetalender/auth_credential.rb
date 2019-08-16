module Meetalender
  class AuthCredential < ApplicationRecord
    # TODO(Schau): There might be a better place for this function
    def self.expand_env(str)
      str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV[$1] }
    end

    attr_encrypted :access_token, key: Rails.application.secrets.secret_key_base.to_s.bytes[0..31].pack("c" * 32)
    attr_encrypted :refresh_token, key: Rails.application.secrets.secret_key_base.to_s.bytes[0..31].pack("c" * 32)

    def scope
      parsed_scope = JSON.parse(self.scope_json)
      parsed_scope.blank? ? [] : parsed_scope.to_a
    end
    def scope=(new_scope)
      self.scope_json = new_scope.to_json.to_s
    end
  end
end
