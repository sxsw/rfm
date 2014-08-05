shared_examples_for "ActiveModel" do
  require 'minitest'
  include Minitest::Assertions
  include ActiveModel::Lint::Tests

  attr_accessor :assertions

  def initialize
    self.assertions = 0
    super
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
