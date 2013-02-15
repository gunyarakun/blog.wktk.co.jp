require 'rubygems'
require 'rake'
require 'yaml'
require 'time'

SOURCE = '.'
CONFIG = {
  'version' => '0.2.13',
  'themes' => File.join(SOURCE, '_includes', 'themes'),
  'layouts' => File.join(SOURCE, '_layouts'),
  'posts' => File.join(SOURCE, '_posts'),
  'post_ext' => 'md',
  'theme_package_version' => '0.1.0'
}

# Path configuration helper
module WktkBlog
  class Path
    SOURCE = '.'
    Paths = {
      :layouts => '_layouts',
      :themes => '_includes/themes',
      :theme_assets => 'assets/themes',
      :theme_packages => '_theme_packages',
      :posts => '_posts'
    }

    def self.base
      SOURCE
    end

    # build a path relative to configured path settings.
    def self.build(path, opts = {})
      opts[:root] ||= SOURCE
      path = "#{opts[:root]}/#{Paths[path.to_sym]}/#{opts[:node]}".split("/")
      path.compact!
      File.__send__ :join, path
    end
  end #Path
end #WktkBlog

# Load custom rake scripts
Dir['_rake/*.rake'].each { |r| load r }
