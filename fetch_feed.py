#!/usr/bin/env python

from HTMLParser import HTMLParser
import gzip
import json
import os
import shlex
import string
import subprocess
import unicodedata

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

    missing_mp4s = ''

    while True: 
        print 'Fetching page %i' % page
        url = 'http://api.npr.org/query?id=92071316&apiKey=%s&output=json&startNum=%i&numResults=40' % (os.environ['NPR_API_KEY'], page * 40)
        print url
        response = requests.get(url)

        data = response.json() 

        if 'message' in data and data['message'][0]['id'] == '401':
            print data['message']
            break

        for story in data['list']['story']:
            title = story['title']['$text'].replace(': Tiny Desk Concert', '')
            print title

            item = {
                'id': story['id'],
                'title': title,
                'searchTitle': searchify_title(title), 
                'sortTitle': sortify_title(title), 
                'titleSeason': 'Tiny Desk Concerts',
                'description': strip_tags(story['miniTeaser']['$text']),
                'sdPosterUrl': None,
                'hdPosterUrl': None,
                'length': int(story['multimedia'][0]['duration']['$text']),
                'releaseDate': None,
                'streamFormat': 'mp4',
                'streamBitrates': [],
                'streamUrls': [],
                'streamQualities': [],
                'isHD': True,
                'hdBranded': True
            }

            alt_image_url = story['multimedia'][0]['altImageUrl']['$text']

            # Yes, I know this is a hack, but we don't want to urlencode the protocol or domain
            item['sdPosterUrl'] = alt_image_url.replace(' ', '%20') + '?s=2'
            item['hdPosterUrl'] = alt_image_url.replace(' ', '%20') + '?s=3'

            # Formatted as: "Mon, 11 Mar 2013 14:03:00 -0400"
            pub_date = story['pubDate']['$text']
            dt = parse(pub_date)

            item['releaseDate'] = dt.strftime('%B %d, %Y') 

            if 'mp4' not in story['multimedia'][0]['format']:
                print '--> No mp4 video, skipping!'

                missing_mp4s += '%s, %s\n' % (item['id'], item['title'])
                
                continue

            video_url = story['multimedia'][0]['format']['mp4']['$text']
            
            for bitrate in BITRATES:
                item['streamBitrates'].append(int(bitrate / 1024))
                item['streamUrls'].append(video_url.replace('-n', '-n-%i' % bitrate))
                item['streamQualities'].append('SD')

            # The last item is full resolution 
            item['streamUrls'][-1] = video_url
            item['streamQualities'][-1] = 'HD'

            output.append(item)

        page += 1

    print 'Saving %i concerts' % len(output)

    with gzip.open('feed.json', 'wb') as f:
        f.write(json.dumps(output))

    with open('missing_mp4s.txt', 'w') as f:
        f.write(missing_mp4s)

    print 'Deploying to S3'

    subprocess.Popen(shlex.split(UPLOAD_CMD), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def searchify_title(title):
    return ''.join(x for x in unicodedata.normalize('NFKD', title) if x in string.printable)

def sortify_title(title):
    title = searchify_title(title)

    return ''.join(x for x in title if x in string.letters + string.digits + ' ').lower()

if __name__ == '__main__':
    main()
