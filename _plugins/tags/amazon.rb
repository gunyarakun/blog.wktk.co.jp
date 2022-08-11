# -*- encoding: utf-8 -*-

# Amazon Tag Plugin for Jekyll
# ============================
#
# How to use
# ----------
#
#   1. Install this script to `_plugin` folder.
#   2. Create cache directory `_caches/amazon`.
#   3. Install vacuum(`gem install vacuum`).
#   4. Write access key information to `_amazon.yml' in YAML format.
#      (ex)
#        jp:
#          AWS_access_key_id: XXXXXXXXXXXXXXXXXXXX
#          AWS_secret_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#          associate_tag: nitoyonjp-22
#        us:
#          AWS_access_key_id: XXXXXXXXXXXXXXXXXXXX
#          AWS_secret_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#          associate_tag: nitoyoncom-22
#
# Embed amazon
# ------------
#
#     {% amazon jp:B000002JC2:title %}
#     => <a href="...">Book title</a>
#
#     {% amazon jp:B000002JC2:detail %}
#     => <div class="hatena-asin-detail">
#          <a href="...">Book title</a>
#          <div class="hatena-asin-detail-info">
#             :
#          </div>
#        </div>
#
# License
# -------
#
# Copyright 2012, nitoyon. All rights reserved.
# BSD License.

module Jekyll

  class AmazonTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      params = params.strip
      if /^(\w+):(\w+):(title|detail)$/.match(params)
        @lang = $1
        @amazon_id = $2
        @type =$3
      end
    end

    def render(context)
      require 'cgi'
      if @lang.nil?
        "(invalid amazon tag parameter)"
      elsif @type == "title"
        begin
          data = load_product_data(@lang, @amazon_id, context)
          %(<a href="#{data[:detailUrl]}" target="_blank">#{CGI.escapeHTML(data[:title])}</a>)
        rescue
          "(cannot get Amazon #{@lang} #{@amazon_id})"
        end
      elsif @type == "detail"
        begin
          data = load_product_data(@lang, @amazon_id, context)
        rescue
          return "(cannot get Amazon #{@lang} #{@amazon_id})"
        end

        labels = [
          { :key => :author , :label => '作者' },
          { :key => :publisher , :label => '出版社/メーカー' },
          { :key => :date , :label => '発売日' },
          { :key => :media , :label => 'メディア' },
        ]
        htmls = []
        labels.each do |l|
          v = data[l[:key]]
          next if v.nil?
          htmls << %(<li><span class="hatena-asin-detail-label">#{l[:label]}:</span> #{CGI.escapeHTML(data[l[:key]])}</li>)
        end

        html = htmls.join("\n")

        %(<div class="hatena-asin-detail">
  <a href="#{data[:detailUrl]}" target="_blank"><img src="#{data[:mediumThumnail]}" class="hatena-asin-detail-image" alt="#{CGI.escapeHTML(data[:title])}" title="#{CGI.escapeHTML(data[:title])}"></a>
  <div class="hatena-asin-detail-info">
    <p class="hatena-asin-detail-title"><a href="#{data[:detailUrl]}" target="_blank">#{CGI.escapeHTML(data[:title])}</a></p>
  </div>
  <div class="hatena-asin-detail-foot"></div>
</div>)
      else
        "(invalid type)"
      end
    end

    def load_product_data(lang, amazon_id, context)
      doc = load_product_with_cache(lang, amazon_id, context)

      item = doc.dig('ItemsResult', 'Items', 0)
      item_info = item['ItemInfo']
      byline = item_info['ByLineInfo']

      def author(byline)
        return nil if byline.nil?
        if byline['Contributors'] and byline['Contributors'].length > 0
          return byline['Contributors'].map{|c| c['Name']}.join(',')
        end
        nil
      end

      data = {
        :detailUrl      => item['DetailPageURL'],
        :reviewUrl      => nil,
        :mediumThumnail => item.dig('Images', 'Primary', 'Medium', 'URL'),
        :title          => item.dig('ItemInfo', 'Title', 'DisplayValue'),
        :author         => author(byline),
        :publisher      => byline.dig('Manufacturer', 'DisplayValue'),
        :date           => item_info.dig('ContentInfo', 'PublicationDate', 'DisplayValue') ||
                           item_info.dig('ProductInfo', 'ReleaseDate', 'DisplayValue'),
        :media          => item_info.dig('ContentInfo', 'Classifications', 'ProductGroup', 'DisplayValue'),
      }
    end

    def load_product_with_cache(lang, amazon_id, context)
      config_path = File.join(context.registers[:site].source, '_amazon.yml')
      caches_dir = File.join(context.registers[:site].source, '_caches/amazon')
      cache_path = File.join(caches_dir, "#{lang}.#{amazon_id}.json")
      unless FileTest.directory?(caches_dir)
        puts "Cache directory doesn't exist: #{caches_dir}"
        raise "Cache directory doesn't exist: #{caches_dir}"
      end

      doc = nil
      if FileTest.file?(cache_path)
        open(cache_path) { |f| doc = JSON.load(f) }
      end

      if doc.nil?
        puts "loading Amazon #{lang} #{amazon_id}"
        doc = load_product_from_web(lang, amazon_id, config_path)
        unless doc.has_key?('ItemsResult')
          puts doc
          raise "Invalid Amazon: #{lang} #{amazon_id}"
        end
        open(cache_path, 'w') { |f| JSON.dump(doc, f) }
        puts "loaded Amazon #{lang} #{amazon_id}"
      end

      doc
    end

    def load_product_from_web(lang, amazon_id, config_path)
      require 'vacuum'

      # load config from config_path
      conf = {}
      begin
        open(config_path) { |f| conf = YAML.load(f.read) }
      rescue => err
        puts err
        raise err
      end

      request = Vacuum.new(
        marketplace: lang.upcase, # ex.) JP
        access_key: conf[lang]['AWS_access_key_id'],
        secret_key: conf[lang]['AWS_secret_key'],
        partner_tag: conf[lang]['associate_tag']
      )
      response = request.get_items(
        item_ids: [amazon_id],
        resources: ['Images.Primary.Medium', 'ItemInfo.Title', 'ItemInfo.ByLineInfo', 'ItemInfo.Classifications', 'ItemInfo.ContentInfo', 'ItemInfo.ProductInfo'],
      )

      sleep 7

      response.to_h
    end
  end
end

Liquid::Template.register_tag('amazon', Jekyll::AmazonTag)
