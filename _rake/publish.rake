desc 'Publish to S3'
task :publish do
  system('aws', 's3', 'sync', './_site', 's3://blog.wktk.co.jp/', '--profile', 'wktk')
  system('aws', 'cloudfront', 'create-invalidation', '--profile', 'wktk', '--distribution-id', 'E1N7AW1W9DJBU', '--paths', '/ja/', '/ja/feed/atom.xml', '/ja/feed/rss.xml', '/sitemap.txt')
end # task :publish
