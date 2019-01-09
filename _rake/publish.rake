desc 'Publish to S3'
task :publish do
  system('aws', 's3', 'sync', './_site', 's3://blog.wktk.co.jp/', '--profile', 'wktk')
end # task :publish
