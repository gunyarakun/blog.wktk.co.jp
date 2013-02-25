# This plugin modifies Site class and adds following functions.
#
#  - Reload modified plugin in --server and --auto mode.
#  - Skip unmodified post in --server and --auto mode.
#
# Dependent plugins:
#  - post_yaml_cache plugin
#  - archive plugin
#  - lang plugin

module Jekyll
  class Post
    attr_accessor :skipped, :yaml_modified, :modified

    def source
      File.join(@base, @name)
    end
  end

  class Page
    attr_accessor :skipped, :yaml_modified, :modified

    def source
      File.join(@base, @dir, @name)
    end
  end

  class Layout
    attr_accessor :yaml_modified, :modified
  end

  class Site
    def is_modified_only
      self.config['server'] && self.config['auto']
    end

    # Render the site to the destination.
    #
    # Returns nothing.
    #
    # Added logging and reloading plugins.
    def process
      t_total = Time.now
      t_reset = Time.now
      puts "process: resetting"
      self.reset
      t_reset = Time.now - t_reset

      t_plugin = Time.now
      puts "process: reload_plugin"
      self.reload_plugin
      t_plugin = Time.now - t_plugin

      t_read = Time.now
      puts "process: reading"
      self.read
      t_read = Time.now - t_read

      t_generate = Time.now
      puts "process: generating"
      self.generate
      t_generate = Time.now - t_generate

      t_render = Time.now
      puts "process: rendering"
      self.render
      t_render = Time.now - t_render

      t_archive = Time.now
      puts "process: archives"
      self.generate_archives
      t_archive = Time.now - t_archive

      t_lang = Time.now
      puts "process: languages"
      self.generate_languages
      t_lang = Time.now - t_lang

      t_cleanup = Time.now
      puts "process: cleanuping"
      self.cleanup
      t_cleanup = Time.now - t_cleanup

      t_write = Time.now
      puts "process: writing"
      self.write
      t_write = Time.now - t_write

      t_total = Time.now - t_total

      puts "reset:         #{t_reset} sec"
      puts "reload_plugin: #{t_plugin} sec"
      puts "read:          #{t_read} sec"
      puts "generate:      #{t_generate} sec"
      puts "render:        #{t_render} sec"
      puts "archive:       #{t_archive} sec"
      puts "languages:     #{t_lang} sec"
      puts "cleanup:       #{t_cleanup} sec"
      puts "writing:       #{t_write} sec"
      puts "total:         #{t_total} sec"
    rescue Exception => e
      puts "Exception in process: #{e} #{e.backtrace.join("\n")}"
      raise e
    end

    def reload_plugin
      if self.config['server'] && self.config['auto']
        Dir[File.join(self.plugins, "**/*.rb")].each do |f|
          load f
        end
      end
    end

    # Remove orphaned files and empty directories in destination.
    #
    # Returns nothing.
    def cleanup
      # all files and directories in destination, including hidden ones
      dest_files = Set.new
      Dir.glob(File.join(self.dest, "**", "*"), File::FNM_DOTMATCH) do |file|
        dest_files << file unless file =~ /\/\.{1,2}$/ || file =~ /\/\.git/
      end

      # files to be written
      files = Set.new
      self.posts.each do |post|
        files << post.destination(self.dest)
      end
      self.pages.each do |page|
        files << page.destination(self.dest)
      end
      self.static_files.each do |sf|
        files << sf.destination(self.dest)
      end

      # adding files' parent directories
      dirs = Set.new
      dirs << self.dest
      files.each { |file|
        dir = File.dirname(file)
        until dirs.include?(dir) or dir == File.dirname(dir)
          dirs << dir
          dir = File.dirname(dir)
        end
      }
      files.merge(dirs)

      obsolete_files = dest_files - files

      require 'pp'
      puts 'obsolete files:'
      pp obsolete_files

      FileUtils.rm_rf(obsolete_files.to_a)
    end

    # Render the site to the destination.
    #
    # Returns nothing.
    def render
      payload = site_payload
      self.posts.each do |post|
        post.skipped = true
        self.render_if_modified(post, payload)
      end

      self.pages.each do |page|
        page.skipped = true
        self.render_if_modified(page, payload)
      end

      self.categories.values.map { |ps| ps.sort! { |a, b| b <=> a } }
      self.tags.values.map { |ps| ps.sort! { |a, b| b <=> a } }
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end

    def render_if_modified(page, payload)
      begin
        page.skipped = !self.check_render(page)
      rescue Exception => e
        puts "Failed to check render #{page.destination('/')}: #{e}"
        page.skipped = false
      end
      page.render(self.layouts, payload) unless page.skipped
    end

    def check_render(page)
      unless self.is_modified_only
        true
      else
        default_update_policy = self.config['default_update_policy']
        @template_cache ||= {}

        if page.data.has_key?("update_policy")
          update_policy = page.data["update_policy"]
        elsif page.class == Page && default_update_policy && default_update_policy['page']
          update_policy = default_update_policy['page']
        elsif page.class == Post && default_update_policy && default_update_policy['post']
          update_policy = default_update_policy['post']
        else
          update_policy = "{% if page.raw.modified %}1{% endif %}"
        end

        # performance improvement (skip Liquid rendering)
        if update_policy == "{% if page.raw.modified %}1{% endif %}"
          return page.modified
        elsif update_policy == "{% if page.raw.modified or page.previous.raw.yaml_modified or page.next.raw.yaml_modified %}1{% endif %}"
          return (page.modified || 
                  page.previous && page.previous.yaml_modified || 
                  page.next && page.next.yaml_modified)
        elsif update_policy == "{% for post in page.posts %}{% if post.raw.yaml_modified %}1{% endif %}{%endfor%}"
          for post in page.data["posts"]
            return true if post.yaml_modified
          end
          return false
        end

        unless @template_cache.has_key? update_policy
          @template_cache[update_policy] = Liquid::Template.parse(update_policy)
        end
        template = @template_cache[update_policy]

        update = template.render(
          { "page" => page }.deep_merge(site_payload), 
          { :filters => [Jekyll::Filters], :registers => { :site => self } })
        puts "#{page.destination('/')} updated: #{update.strip}" unless update.strip.empty?
        !update.strip.empty?
      end
    end

    # Write static files, pages, and posts.
    #
    # Write only modified file.
    #
    # Returns nothing.
    def write
      self.posts.each do |post|
        next if post.skipped
        post.write(self.dest)
        puts "writing " + post.destination('/')
      end
      self.pages.each do |page|
        next if page.skipped
        page.write(self.dest)
        puts "writing " + page.destination('/')
      end
      self.static_files.each do |sf|
        sf.write(self.dest)
      end
    end
  end
end