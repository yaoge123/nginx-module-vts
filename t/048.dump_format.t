# vi:set ft=perl ts=4 sw=4 et fdm=marker:

# The dump header used to carry nginx_version in its version field and nothing
# in the restore path read it. Those dumps are still readable: the node layout
# did not change when the header grew a module format version and node size.

use Test::Nginx::Socket;
use Config;
use File::Spec ();

my $DumpFile = File::Spec->rel2abs('t/vts.dump-format');

$ENV{TEST_NGINX_DUMP_FILE} = $DumpFile;

unlink $DumpFile;

add_cleanup_handler(sub { unlink $DumpFile });

plan tests => repeat_each() * 11;
no_shuffle();
run_tests();

__DATA__

=== TEST 1: a current dump is written
--- http_config
    vhost_traffic_status_zone;
    vhost_traffic_status_dump $TEST_NGINX_DUMP_FILE 1s;
--- config
    location /v {
        set $vol legacy;
        vhost_traffic_status_filter_by_set_key $vol legacy::$server_name;
        return 200 "OK";
    }
--- request
GET /v/file.txt
--- response_body_like: OK
--- wait: 2

=== TEST 2: a pre-version dump is restored
--- post_setup_server_root
    my $dump = $ENV{TEST_NGINX_DUMP_FILE};
    open my $in, '<', $dump or die "cannot open $dump: $!";
    binmode $in;
    local $/;
    my $data = <$in>;
    close $in;

    my $uint_fmt = $Config::Config{ptrsize} == 8 ? 'Q' : 'L!';
    my $legacy = pack("a128 $uint_fmt $uint_fmt",
                      'ngx_http_vhost_traffic_status', 0, 1031004);
    my $current = pack("a128 $uint_fmt $uint_fmt $uint_fmt",
                       'x', 0, 0, 0);

    substr($data, 0, length($current), $legacy);

    open my $out, '>', $dump or die "cannot open $dump: $!";
    binmode $out;
    print {$out} $data;
    close $out;
--- http_config
    vhost_traffic_status_zone;
    vhost_traffic_status_dump $TEST_NGINX_DUMP_FILE 1s;
--- config
    # changed comment: force a fresh worker for the legacy restore
    location /status {
        vhost_traffic_status_display;
        vhost_traffic_status_display_format json;
        access_log off;
    }
--- request
GET /status/format/json
--- response_body_like: filterZones.*legacy::localhost.*?legacy.*?requestCounter\":[1-9]
--- error_log
dump_restore::dump_header_read() legacy version:1031004, restoring

=== TEST 3: a dump from a newer format version is rejected
--- post_setup_server_root
    my $dump = $ENV{TEST_NGINX_DUMP_FILE};
    open my $out, '>', $dump or die "cannot open $dump: $!";
    binmode $out;
    my $uint_fmt = $Config::Config{ptrsize} == 8 ? 'Q' : 'L!';
    print {$out} pack("a128 $uint_fmt $uint_fmt $uint_fmt",
                      'ngx_http_vhost_traffic_status', 0, 3, 0);
    print {$out} "\0" x 64;
    close $out;
--- http_config
    vhost_traffic_status_zone;
    vhost_traffic_status_dump $TEST_NGINX_DUMP_FILE 1s;
--- config
    location /status {
        vhost_traffic_status_display;
        vhost_traffic_status_display_format json;
        access_log off;
    }
--- request
GET /status/format/json
--- response_body_like: "serverZones"
--- error_log
dump_restore::dump_header_read() version:3 failed

=== TEST 4: a dump with the wrong node size is rejected
--- post_setup_server_root
    my $dump = $ENV{TEST_NGINX_DUMP_FILE};
    open my $out, '>', $dump or die "cannot open $dump: $!";
    binmode $out;
    my $uint_fmt = $Config::Config{ptrsize} == 8 ? 'Q' : 'L!';
    print {$out} pack("a128 $uint_fmt $uint_fmt $uint_fmt",
                      'ngx_http_vhost_traffic_status', 0, 2, 1);
    print {$out} "\0" x 64;
    close $out;
--- http_config
    vhost_traffic_status_zone;
    vhost_traffic_status_dump $TEST_NGINX_DUMP_FILE 1s;
--- config
    location /status {
        vhost_traffic_status_display;
        vhost_traffic_status_display_format json;
        access_log off;
    }
--- request
GET /status/format/json
--- response_body_like: "serverZones"
--- error_log
dump_restore::dump_header_read() node size:1 failed
