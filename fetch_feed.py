#!/usr/bin/env python

import json
import os

from dateutil.parser import parse
import requests

response = requests.get('http://api.npr.org/query?id=92071316&apiKey=%s&output=json&numResults=10' % os.environ['NPR_API_KEY'])

data = response.json() 

output = []

for story in data['list']['story']:
    print story['title']['$text']

    item = {
        'Id': story['id'],
        'Title': story['title']['$text'],
        'Description': story['miniTeaser']['$text'],
        'SDPosterUrl': None,
        'HDPosterUrl': None,
        'Length': story['multimedia'][0]['duration']['$text'],
        'ReleaseDate': None,
        'StreamFormat': 'mp4',
        'Stream': {
            'Url': None
        }
    }

    alt_image_url = story['multimedia'][0]['altImageUrl']['$text']

    item['SDPosterUrl'] = alt_image_url + '?s=2'
    item['HDPosterUrl'] = alt_image_url + '?s=3'


    # Formatted as: "Mon, 11 Mar 2013 14:03:00 -0400"
    pub_date = story['pubDate']['$text']
    dt = parse(pub_date)

    item['ReleaseDate'] = dt.strftime('%B %d, %Y') 

    video_url = story['multimedia'][0]['format']['mp4']['$text']
    item['Stream']['Url'] = video_url #.replace('asc', 'ascvid').replace('.mp4', '-n-1200000.mp4')

    output.append(item)

print 'Saving %i concerts' % len(output)

with open('source/tinydesk.json', 'w') as f:
    json.dump(output, f, indent=4)
