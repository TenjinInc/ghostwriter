# frozen_string_literal: true

require 'spec_helper'

describe Ghostwriter do
   it 'should have a version number' do
      expect(Ghostwriter::VERSION).not_to be nil
   end
end
