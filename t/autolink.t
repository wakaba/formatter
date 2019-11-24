use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use Tests;
use Web::Encoding;

Test {
  my ($c, $client) = @{$_[0]};
  return $client->request (path => ['autolink'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 405;
    } $c;
  });
} n => 1, name => 'GET is not allowed';

for (
  ["", ""],
  ["anvc def", "anvc def"],
  ["http://bad.foo.test/aa", qq{<a href="http://bad.foo.test/aa" class=url-link>http://bad.foo.test/aa</a>}],
  ["[http://bad.foo.test/aa:title]", qq{[<a href="http://bad.foo.test/aa:title" class=url-link>http://bad.foo.test/aa:title</a>]}],
  ["[https://aba.test/aew43aat33333:embed]", qq{[<a href="https://aba.test/aew43aat33333:embed" class=url-link>https://aba.test/aew43aat33333:embed</a>]}],
  ["[https://twitter.com/bukkenfan/status/836562615081947136:embed]", qq{[<a href="https://twitter.com/bukkenfan/status/836562615081947136:embed" class=url-link>https://twitter.com/bukkenfan/status/836562615081947136:embed</a>]}],
  [q{https://foo.bar/test:detail}, qq{<a href="https://foo.bar/test:detail" class=url-link>https://foo.bar/test:detail</a>}],
  [q{[tex:a^b + c < 1]}, qq{[tex:a^b + c &lt; 1]}],
) {
  my ($input, $expected, %args) = @$_;
  Test {
    my ($c, $client) = @{$_[0]};
    return $client->request (
      path => ['autolink'],
      method => 'POST',
      headers => {origin => 'https://pass1.test'},
      body => (encode_web_utf8 $input),
      params => \%args,
    )->then (sub {
      my $res = $_[0];
      test {
        is $res->status, 200;
        is $res->header ('access-control-allow-origin'), 'https://pass1.test';
        is decode_web_utf8 ($res->body_bytes), $expected;
      } $c;
    });
  } n => 3, name => ['converted', $input];
}

Test {
  my ($c, $client) = @{$_[0]};
  return $client->request (
    path => ['autolink'],
    method => 'POST',
    headers => {origin => 'https://bad1.test'},
    body => rand,
  )->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
    } $c;
  });
} n => 1, name => 'bad origin';

Test {
  my ($c, $client) = @{$_[0]};
  return $client->request (
    path => ['autolink'],
    method => 'POST',
    body => rand,
  )->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
    } $c;
  });
} n => 1, name => 'no origin';

RUN;

=head1 LICENSE

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
