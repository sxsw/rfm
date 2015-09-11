
# Copied from spec run deprecation warning on ruby 2.1.3@rfm:
#
# The semantics of `described_class` in a nested `describe <SomeClass>`
# example group are changing in RSpec 3. In RSpec 2.x, `described_class`
# would return the outermost described class (Rfm::Base).
# In RSpec 3, it will return the innermost described class (TestModel).
# In general, we recommend not describing multiple classes or objects in a
# nested manner as it creates confusion.
# 
# To make your code compatible with RSpec 3, change from `described_class` to a reference
# to `TestModel`, or change the arg of the inner `describe` to a string.
# (Called from /Users/wbr/Documents/programming/gitprojects/GinjoRfm.git/spec/active_model_lint.rb:20:in `model')



shared_examples_for "ActiveModel" do
  require 'minitest'
  include Minitest::Assertions
  include ActiveModel::Lint::Tests

  attr_accessor :assertions

  def initialize(*args)
    self.assertions = 0
    super(*args)
  end

  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

  def model
    subject
  end
end
