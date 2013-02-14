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

desc 'Launch preview environment'
task :preview do
  system('jekyll', '--auto', '--server')
end # task :preview

# Internal: Download and process a theme from a git url.
# Notice we don't know the name of the theme until we look it up in the manifest.
# So we'll have to change the folder name once we get the name.
#
# url - String, Required url to git repository.
#
# Returns theme manifest hash
def theme_from_git_url(url)
  tmp_path = WktkBlog::Path.build(:theme_packages, :node => "_tmp")
  abort("rake aborted: system call to git clone failed") if !system("git clone #{url} #{tmp_path}")
  manifest = verify_manifest(tmp_path)
  new_path = WktkBlog::Path.build(:theme_packages, :node => manifest["name"])
  if File.exist?(new_path) && ask("=> #{new_path} theme package already exists. Override?", ['y', 'n']) == 'n'
    remove_dir(tmp_path)
    abort("rake aborted: '#{manifest["name"]}' already exists as theme package.")
  end

  remove_dir(new_path) if File.exist?(new_path)
  mv(tmp_path, new_path)
  manifest
end

# Internal: Process theme package manifest file.
#
# theme_path - String, Required. File path to theme package.
#        
# Returns theme manifest hash
def verify_manifest(theme_path)
  manifest_path = File.join(theme_path, "manifest.yml")
  manifest_file = File.open( manifest_path )
  abort("rake aborted: repo must contain valid manifest.yml") unless File.exist? manifest_file
  manifest = YAML.load( manifest_file )
  manifest_file.close
  manifest
end

def ask(message, valid_options)
  if valid_options
    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

#Load custom rake scripts
Dir['_rake/*.rake'].each { |r| load r }
