#!/usr/bin/env perl
use strict;
use warnings;

# tested with:
#root@parse-local:~/parse-backup# perl -V | head -1
#Summary of my perl5 (revision 5 version 18 subversion 2) configuration:
#root@parse-local:~/parse-backup# jq -V | head -1
#jq version 1.3
#root@parse-local:~/parse-backup# curl -V | head -1
#curl 7.35.0 (x86_64-pc-linux-gnu) libcurl/7.35.0 OpenSSL/1.0.1f zlib/1.2.8 libidn/1.28 librtmp/2.3

my $parse_url = 'https://api.parse.com/1/classes';
my $curl_prefix = q(curl -vv -X GET -H "X-Parse-Application-Id: ..." -H "X-Parse-REST-API-Key: ..." );
my $limit = 1000;
my $qpm = 1800;

my @classes = qw(
_User
...
);

my $qst = time;
my $reqs = 0;

for my $class (@classes) {
    my $createdAt = "1970-01-01T00:00:00.000Z";
    my $total_fetched = 0;
    my $objects_fetched = $limit;
    my $fname = "";
    
    while ($objects_fetched >= $limit) {
        for (my $skip = 0; $skip < 10000 && $objects_fetched >= $limit; $skip += $limit) {
            log_debug("Start fetching $class from $createdAt with skip $skip ...");

            my $cmd = join(" ",
                $curl_prefix,
                "--data-urlencode 'order=createdAt'",
                "--data-urlencode 'limit=$limit'",
                "--data-urlencode 'skip=$skip'",
                "--data-urlencode 'order=createdAt'",
                q(--data-urlencode 'where={"createdAt":{"$gt": { "__type": "Date", "iso": ") . $createdAt . q(" }}}'),
            );
            $fname = "$class.json.$createdAt.$skip";
            myqx(qq($cmd $parse_url/$class > $fname));
        
            $reqs++;
            if ($reqs >= 1800) {
                my $to_sleep = 60 - (time - $qst);
                $qst = time;
                $reqs = 0;

                log_debug("Going to sleep $to_sleep sec ...");
                sleep($to_sleep);
            }

            $objects_fetched = myqx(qq(jq '[.results[].objectId] | length' < '$fname'));
            if ($objects_fetched !~ /\d+/) {
                log_debug(sprintf("Bad objects fetched: %s", $objects_fetched || "undef"));
                $objects_fetched = 0;
            }
            $total_fetched += $objects_fetched;
            log_debug("Fetched $objects_fetched obj with last date $createdAt");
        }
        if ($objects_fetched < $limit) {
            log_debug("Done fetching $class: $total_fetched obj with last date $createdAt");
            next;
        }
        
        $createdAt = myqx(qq(jq '.results[].createdAt' < '$fname' | tail -n 1));
        ($createdAt) = ($createdAt =~ m/"(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d.*)"/);
        if (!$createdAt) {
            log_debug(sprintf("Bad createdAt: %s", $createdAt || "undef"));
            log_debug("Done fetching $class: $total_fetched obj with last date $createdAt");
            next;
        }
        log_debug("Continue fetching $class: $objects_fetched obj with last date $createdAt");
    }
}

sub log_debug {
    chomp(my $date = qx(date));
    warn "[$date] @_\n";
}

sub myqx {
    my ($cmd) = @_;
    log_debug("Going to run $cmd");
    chomp(my $res = qx($cmd));
    return $res;
}
