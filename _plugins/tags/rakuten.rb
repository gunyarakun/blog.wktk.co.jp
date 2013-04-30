# -*- encoding: utf-8 -*-

# Rakuten Tag Plugin for Jekyll
# =============================
#
# How to use
# ----------
#
#   1. Install this script to `_plugin` folder.
#   2. Create cache directory `_caches/rakuten`.
#   3. Write access key information to `_rakuten.yml' in YAML format.
#      (ex)
#        applicationId: xxxxxxxx
#        affiliateId: XXXXXXXXXXXXXXXXXXXX
#
# Embed rakuten
# ------------
#
#     {% rakuten keyword:楽天:title  %}
#     => <a href="...">Book title</a>
#
#     {% rakuten genreId:559887:title  %}
#     => <a href="...">Book title</a>
#
#     {% rakuten itemCode:kys:10173199:title %}
#     => <a href="...">Book title</a>
#
#     {% rakuten keyword:楽天:detail %}
#     => <div class="rakuten-detail">
#          <a href="...">Book title</a>
#          <div class="rakuten-detail-info">
#             :
#          </div>
#        </div>
#
# License
# -------
#
# Copyright 2013, Tasuku SUENAGA a.k.a. gunyarakun. All rights reserved.
# Based on Amazon Tag Plugin by nitoyon.
# BSD License.

require 'cgi'
require 'json'
require 'yaml'
require 'open-uri'

module Jekyll

  class RakutenTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      params = params.strip
      if /^(\w+):(.+):(title|detail)$/.match(params)
        @query_type = $1.to_sym
        case @query_type
        when :keyword, :genreId, :itemCode
          @query = $2
          @output_type = $3.to_sym
        end
      end
    end

    def render(context)
      if @output_type.nil?
        "(invalid rakuten tag parameter)"
      elsif @output_type == :title
        datas = load_product_data(@query_type, @query, context)
        datas.map {|data|
          %(<a href="#{data[:affiliateUrl]}">#{CGI.escapeHTML(data[:itemName])}</a>)
        }.join(' / ')
      elsif @output_type == :detail
        datas = load_product_data(@query_type, @query, context)

        datas.map {|data|
          %(<div class="rakuten-detail">
  <a href="#{data[:affiliateUrl]}"><img src="#{data[:mediumImageUrls][0]}" class="rakuten-detail-image" alt="#{CGI.escapeHTML(data[:itemName])}" title="#{CGI.escapeHTML(data[:itemName])}"></a>
  <div class="rakuten-detail-info">
    <p class="rakuten-detail-title"><a href="#{data[:affiliateUrl]}">#{CGI.escapeHTML(data[:itemName])}</a></p>
    <p class="rakuten-detail-desc">
      #{CGI.escapeHTML(data[:itemCaption][0..100])}
    </p>
  </div>
  <div class="rakuten-detail-foot"></div>
</div>)
        }.join("\n")
      else
        "(invalid type)"
      end
    end

    def load_product_data(query_type, query, context)
      res = load_product_with_cache(query_type, query, context)
      affiliateId = res['affiliateId']

      res['Items'].map {|item|
        item = item['Item']
        {
          :itemName => item['itemName'],
          :itemCaption => item['itemCaption'],
          :affiliateUrl => "http://hb.afl.rakuten.co.jp/hgc/#{affiliateId}/?pc=" + CGI.escape(item['itemUrl']),
          :mediumImageUrls => item['imageFlag'] == 0 ? nil : item['mediumImageUrls'].map{|miu| miu['imageUrl']},
        }
      }
    end

    def load_product_with_cache(query_type, query, context)
      config_path = File.join(context.registers[:site].source, '_rakuten.yml')
      caches_dir = File.join(context.registers[:site].source, '_caches/rakuten')
      cache_path = File.join(caches_dir, "#{query_type}.#{query}.xml")
      unless FileTest.directory?(caches_dir)
        puts "Cache directory doesn't exist: #{caches_dir}"
        raise "Cache directory doesn't exist: #{caches_dir}"
      end

      res = nil
      if FileTest.file?(cache_path)
        open(cache_path) { |f| res = JSON.parse(f.read) }
      end

      if res.nil?
        puts "loading #{query_type} #{query}"
        res = load_product_from_web(query_type, query, config_path)
        open(cache_path, 'w') { |f| JSON.dump(res, f) }
        puts "loaded"
      end

      res
    end

    def load_product_from_web(query_type, query, config_path)
      # load config from config_path
      conf = {}
      begin
        open(config_path) { |f| conf = YAML.load(f.read) }
      rescue => err
        puts err
        raise err
      end
      url = 'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20130424?'
      conf[query_type.to_s] = query;
      conf.each do |k, v|
        url += '&' + CGI::escape(k) + '=' + CGI::escape(v.to_s)
      end
      open(url) {|f|
        res = JSON.parse(f.read)
        res['affiliateId'] = conf['affiliateId']
        return res
      }
      nil
    end
  end
end

Liquid::Template.register_tag('rakuten', Jekyll::RakutenTag)
