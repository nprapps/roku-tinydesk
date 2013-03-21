#!/usr/bin/env python

import json
import os

import requests

response = requests.get('http://api.npr.org/query?id=92071316&apiKey=%s&output=json' % os.environ['NPR_API_KEY'])

data = response.json() 

output = []

for story in data['list']['story']:
    item = {
        'title': story['title']['$text'],
        'streamformat': 'mp4',
        'stream': {
            'url': ''
        }
    }

    # Audio url: http://pd.npr.org/npr-mp4/npr/asc/2013/03/20130308_asc_hayes.mp4
    # Video url: http://pd.npr.org/npr-mp4/npr/ascvid/2013/03/20130308_ascvid_hayes-n-600000.mp4
    audio_url = story['audio'][0]['format']['mp4']['$text']
    item['stream']['url'] = audio_url.replace('asc', 'ascvid').replace('.mp4', '-n-600000.mp4')

    output.append(item)

with open('source/tinydesk.json', 'w') as f:
    json.dump(output, f, indent=4)
