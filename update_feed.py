#!/usr/bin/env python

import csv
from HTMLParser import HTMLParser
import gzip
import json
import logging
import os
import shlex
import string
import subprocess
import unicodedata

from dateutil.parser import parse
import requests

import app_config

BITRATES = [200000, 500000, 1000000, 2000000]
UPLOAD_CMD = 's3cmd -P --add-header=Cache-Control:max-age=5 --add-header=Content-encoding:gzip --guess-mime-type sync feed.json s3://%s/roku-tinydesk/' % app_config.S3_BUCKETS[0]

logging.basicConfig(filename='/var/log/roku-tinydesk.log', level=logging.DEBUG, format='%(asctime)s: %(message)s')

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
    with open('greatest_hits.txt') as f:
        reader = csv.reader(f)
        greatest_hits = [row[1].strip() for row in reader]

    with open('skip_list.txt') as f:
        reader = csv.reader(f)
        skip_list = [row[1].strip() for row in reader]

    output = []
    page = 0

    missing_mp4s = ''
    zero_length = ''

    while True: 
        logging.info('Fetching page %i' % page)
        url = 'http://api.npr.org/query?id=92071316&apiKey=%s&output=json&startNum=%i&numResults=40' % (os.environ['NPR_API_KEY'], page * 40)
        logging.debug(url)
        response = requests.get(url)

        data = response.json() 

        if 'message' in data and data['message'][0]['id'] == '401':
            break

        for story in data['list']['story']:
            title = story['title']['$text'].replace(': Tiny Desk Concert', '')
            logging.debug(title)

            # Skip any story we've added to the skip list
            if story['id'] in skip_list:
                logging.info('--> In skip list, skipping!')
                continue

            if 'multimedia' not in story or len(story['multimedia']) == 0:
                logging.info('--> No multimedia element, skipping!')
                continue

            item = {
                'id': story['id'],
                'title': title,
                'searchTitle': searchify_title(title), 
                'sortTitle': sortify_title(title), 
                'titleSeason': 'Tiny Desk Concerts',
                'description': strip_tags(story['miniTeaser'].get('$text', '')),
                'sdPosterUrl': None,
                'hdPosterUrl': None,
                'length': int(story['multimedia'][0]['duration'].get('$text', 0)),
                'releaseDate': None,
                'streamFormat': 'mp4',
                'streamBitrates': [],
                'streamUrls': [],
                'streamQualities': [],
                'isHD': True,
                'hdBranded': True,
                'greatestHit': None 
            }

            alt_image_url = story['multimedia'][0]['altImageUrl']['$text']

            # Yes, I know this is a hack, but we don't want to urlencode the protocol or domain
            item['sdPosterUrl'] = alt_image_url.replace(' ', '%20') + '?s=2'
            item['hdPosterUrl'] = alt_image_url.replace(' ', '%20') + '?s=3'

            # Formatted as: "Mon, 11 Mar 2013 14:03:00 -0400"
            story_date = story['storyDate']['$text']
            dt = parse(story_date)

            item['tempDate'] = dt
            item['releaseDate'] = dt.strftime('%B ') + dt.strftime('%d, ').lstrip('0') + dt.strftime('%Y') 

            try:
                item['greatestHit'] = greatest_hits.index(story['id'])
            except ValueError:
                pass

            if 'mp4' not in story['multimedia'][0]['format']:
                logging.debug('--> No mp4 video, skipping!')

                missing_mp4s += '%s, %s\n' % (item['id'], item['title'])
                
                continue

            if item['length'] == 0:
                logging.debug('--> Zero length, including anyway!')

                zero_length += '%s, %s\n' % (item['id'], item['title'])


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

    output = sorted(output, key=lambda k: k['tempDate'])
    output.reverse()
    
    for item in output:
        del item['tempDate']

    if len(output) < 200:
        logging.error('Less than 200 concerts found--sanity check failed! Not updating feed.')
        return

    logging.info('Saving %i concerts' % len(output))

    with gzip.open('feed.json', 'wb') as f:
        f.write(json.dumps(output))

    with open('missing_mp4s.txt', 'w') as f:
        f.write(missing_mp4s)

    with open('zero_length.txt', 'w') as f:
        f.write(zero_length)

    logging.info('Deploying to S3')

    logging.debug(UPLOAD_CMD)
    subprocess.Popen(shlex.split(UPLOAD_CMD), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    logging.info('Done!')

def searchify_title(title):
    return ''.join(x for x in unicodedata.normalize('NFKD', title) if x in string.printable)

def sortify_title(title):
    title = searchify_title(title)

    title = ''.join(x for x in title if x in string.letters + string.digits + ' ').lower()

    if title[0:4] == 'the ':
        title = title[4:]

    return title

if __name__ == '__main__':
    main()
