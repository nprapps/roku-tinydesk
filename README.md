nproku
======

Any experiment. Borrows code from the Roku example apps and from [https://github.com/brianboyer/feedtv](https://github.com/brianboyer/feedtv)

Setup
-----

Set `NPR_API_KEY` in your `.bash_profile`.

```
mkvirtualenv nproku
pip install requirements.txt
```

Generate JSON feed
------------------

```
workon nproku
python fetch_feed.py
```
