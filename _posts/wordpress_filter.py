#!/usr/bin/env python
# -*- coding: utf-8 -*-

from glob import glob
import codecs
import sys
import yaml
from yaml import SafeLoader
import re

hellip_re = re.compile(r'&hellip;')

def construct_binary(loader, node):
  return loader.construct_scalar(node)
def construct_yaml_str(self, node):
  return self.construct_scalar(node)

yaml.add_constructor(u'!binary', construct_binary)
SafeLoader.add_constructor(u'tag:yaml.org,2002:str', construct_yaml_str)

files = glob('*.markdown')
for path in files:
  print path
  content = codecs.open(path, 'r', 'utf-8').read()

  # split header and body
  contents = content.split(u'---')
  header = contents[1]
  body = u'---'.join(contents[2:])

  original_header_data = yaml.load(header)
  new_header_data = {}
  if 'categories' in original_header_data:
    # not converted yet
    new_header_data['tags'] = original_header_data['categories']
    new_header_data['date'] = original_header_data['date']
    new_header_data['title'] = original_header_data['title']
    new_header_data['wordpress_id'] = original_header_data['wordpress_id']
    new_header_data['layout'] = 'post'
    new_header_data['lang'] = 'ja'
    new_header_data['permalink'] = '/archives/%s' % original_header_data['wordpress_id']
  else:
    new_header_data = original_header_data

  header = yaml.dump(new_header_data, allow_unicode = True)
  new_body = re.sub(hellip_re, u'…', body)

  new_content = u'---'.join([u'', u'\n' + header.decode('utf-8'), new_body])
  codecs.open(path, 'w', 'utf-8').write(new_content)
