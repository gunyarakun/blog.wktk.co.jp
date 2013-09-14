desc 'Launch preview environment'
task :preview do
  system('jekyll', 'serve', '--watch')
end # task :preview
