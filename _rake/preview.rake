desc 'Launch preview environment'
task :preview do
  system('jekyll', '--auto', '--server')
end # task :preview
