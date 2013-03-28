#!/usr/bin/env python

from HTMLParser import HTMLParser
import gzip
import json
import os
import shlex
import subprocess

from dateutil.parser import parse
import requests

BITRATES = [200000, 500000, 1000000, 2000000]
UPLOAD_CMD = 's3cmd -P --add-header=Cache-Control:max-age=5 --add-header=Content-encoding:gzip --guess-mime-type sync feed.json s3://apps.npr.org/roku-tinydesk/'

class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()

def main():
    output = []
    page = 0

    while True: 
        print 'Fetching page %i' % page
        response = requests.get('http://api.npr.org/query?id=92071316&apiKey=%s&output=json&startNum=%i&numResults=50' % (os.environ['NPR_API_KEY'], page * 50))

        data = response.json() 

        if 'message' in data and data['message'][0]['id'] == '401':
            break

        for story in data['list']['story']:
            print story['title']['$text']

            item = {
                'Id': story['id'],
                'Title': story['title']['$text'],
                'Description': strip_tags(story['miniTeaser']['$text']),
                'SDPosterUrl': None,
                'HDPosterUrl': None,
                'Length': int(story['multimedia'][0]['duration']['$text']),
                'ReleaseDate': None,
                'StreamFormat': 'mp4',
                'StreamBitrates': [],
                'StreamUrls': [],
                'StreamQualities': [],
                'IsHD': True,
                'HDBranded': True
            }

            alt_image_url = story['multimedia'][0]['altImageUrl']['$text']

            item['SDPosterUrl'] = alt_image_url + '?s=2'
            item['HDPosterUrl'] = alt_image_url + '?s=3'


            # Formatted as: "Mon, 11 Mar 2013 14:03:00 -0400"
            pub_date = story['pubDate']['$text']
            dt = parse(pub_date)

            item['ReleaseDate'] = dt.strftime('%B %d, %Y') 

            if 'mp4' not in story['multimedia'][0]['format']:
                print '--> No mp4 video, skipping!'
                continue

            video_url = story['multimedia'][0]['format']['mp4']['$text']
            
            for bitrate in BITRATES:
                item['StreamBitrates'].append(int(bitrate / 1024))
                item['StreamUrls'].append(video_url.replace('-n', '-n-%i' % bitrate))
                item['StreamQualities'].append('SD')

            # The last item is full resolution 
            item['StreamUrls'][-1] = video_url
            item['StreamQualities'][-1] = 'HD'

            output.append(item)

        page += 1

    print 'Saving %i concerts' % len(output)

    with gzip.open('feed.json', 'wb') as f:
        f.write(json.dumps(output))

    print 'Deploying to S3'

    subprocess.Popen(shlex.split(UPLOAD_CMD), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

if __name__ == '__main__':
    main()
