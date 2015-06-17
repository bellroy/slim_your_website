# Slim Your Website

This is a command line utility that runs multiple requests to a list of URLS and gives you information about how long they take to download, how big they are, how many files get requested, etc. etc.

## Command line usage

You'll need a text file containing a list of URLs you want to test.

```
ruby slim_your_website.rb input_file.txt
```
By default, the utility will run 10 requests against all valid URLs in the file and give you some output, like this:

```
HTTP://GOOGLE.COM
Realtime download times (s): [2.3, 1.5, 1.9, 1.4, 1.4]
Average realtime download time (s): 1.7
Files downloaded: 5
Download size (KB): 70
CPU work times (s): [0.2, 0.2, 0.3, 0.1, 0.2]
Average CPU work time (s): 0.2
Connection speeds (KB/s): [353, 438, 207, 472, 365]
Average connection speed (KB/s): 367

HTTP://TRIKEAPPS.COM
Realtime download times (s): [18.0, 19.0, 17.0, 16.0, 15.0]
Average realtime download time (s): 17.0
Files downloaded: 26
Download size (KB): 203
CPU work times (s): [1.3, 1.6, 1.6, 1.4, 1.5]
Average CPU work time (s): 1.5
Connection speeds (KB/s): [162, 130, 129, 145, 137]
Average connection speed (KB/s): 140
```

If you want to increase or reduce the number of requests, use the second argument on the command line:

```
ruby slim_your_website.rb input_file.txt 3
```
