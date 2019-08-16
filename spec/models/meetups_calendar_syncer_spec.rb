require 'rails_helper'
require 'meetalender/meetups_calendar_syncer'

# TODO(Schau): Write somewhat usefull tests...

RSpec.describe MeetupsCalendarSyncer, type: :model do
  context "Test if testing works" do
    it "testing" do
      expect(MeetupsCalendarSyncer.test_function(1, 2)).to eq(3)
    end
  end
end
