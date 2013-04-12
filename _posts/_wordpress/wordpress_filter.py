#!/usr/bin/env python
# -*- coding: utf-8 -*-

from glob import glob
import codecs
import sys
import yaml
from yaml import SafeLoader
import re

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
  content = u'---'.join(contents[2:])

  original_header_data = yaml.load(header)
  new_header_data = {}
  new_header_data['tags'] = original_header_data['categories']
  new_header_data['date'] = original_header_data['date']
  new_header_data['title'] = original_header_data['title']
  new_header_data['wordpress_id'] = original_header_data['wordpress_id']
  new_header_data['layout'] = 'post'
  new_header_data['lang'] = 'ja'

  header = yaml.dump(new_header_data, allow_unicode = True)

  new_content = u'---'.join([u'', u'\n' + header.decode('utf-8'), content])

  codecs.open(path, 'w', 'utf-8').write(new_content)
