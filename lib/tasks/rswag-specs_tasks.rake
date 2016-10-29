require 'rspec/core/rake_task'

namespace :rswag do
  namespace :specs do

    desc 'Generate Swagger JSON files from integration specs'
    RSpec::Core::RakeTask.new('swaggerize') do |t|
      t.pattern = 'spec/requests/**/*_spec.rb, spec/api/**/*_spec.rb, spec/integration/**/*_spec.rb, spec/app/api/**/*_spec.rb'
      t.rspec_opts = [ '--format Rswag::Specs::SwaggerFormatter', '--order defined' ]
    end
  end
end
