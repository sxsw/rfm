# adapted from rspec-rails http://github.com/rspec/rspec-rails/blob/master/spec/rspec/rails/mocks/mock_model_spec.rb

shared_examples_for "ActiveModel" do
  require 'test/unit/assertions'
  require 'active_model/lint'
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  # to_s is to support ruby-1.9
  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

  def model
    subject
  end
end




# shared_examples_for "ActiveModel" do
#   require 'test/unit/assertions'
#   require 'active_model/lint'
#   include Test::Unit::Assertions
#   include ActiveModel::Lint::Tests
#  
#   ActiveModel::Lint::Tests.public_instance_methods.map { |method| method.to_s }.grep(/^test/).each do |method|
#     example(method.gsub('_', ' ')) { send method }
#   end
# end




# require "active_model/lint"                                                     
# require "test/unit/assertions"                                                  
#                                                                                 
# shared_examples_for "ActiveModel" do                                            
#   include ActiveModel::Lint::Tests                                              
#   include Test::Unit::Assertions                                                
#                                                                                 
#   before { @model = subject }                                                   
#                                                                                 
#   ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/).each do |test|
#     example test.gsub("_", " ") do |example|                                    
#       send test                                                                 
#     end                                                                         
#   end                                                                           
# end   