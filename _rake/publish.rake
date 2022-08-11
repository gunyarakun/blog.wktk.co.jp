desc 'Publish to S3'
task :publish do
  system('aws', 's3', 'sync', './_site', 's3://blog.wktk.co.jp/', '--profile', 'wktk_blog')
  system('aws', 'cloudfront', 'create-invalidation', '--profile', 'wktk_blog', '--distribution-id', 'E1N7AW1W9DJBU', '--paths', '/en/*', '/ja/*', '/sitemap.txt')
end # task :publish
