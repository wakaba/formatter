use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my ($c, $client) = @{$_[0]};
  return $client->request (path => ['hatena'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 405;
    } $c;
  });
} n => 1, name => 'GET is not allowed';

for (
  ["", ""],
  ["anvc def", "<p>anvc def</p>\n"],
  ["http://bad.foo.test/aa", qq{<p><a href="http://bad.foo.test/aa">http://bad.foo.test/aa</a></p>\n}],
  ["[http://bad.foo.test/aa:title]", qq{<p><a href="http://bad.foo.test/aa">http://bad.foo.test/aa</a></p>\n}],
  ["[https://aba.test/aew43aat33333:embed]", qq{<p><a href="https://aba.test/aew43aat33333">https://aba.test/aew43aat33333</a></p>\n}],
  ["[https://twitter.com/bukkenfan/status/836562615081947136:embed]", qq{<p><a href="https://twitter.com/bukkenfan/status/836562615081947136">https://twitter.com/bukkenfan/status/836562615081947136</a></p>\n}],
  [qq{>|js|
function abc () { return x }
||<}, qq{<pre class="code">function abc () { return x }</pre>}],
) {
  my ($input, $expected, %args) = @$_;
  Test {
    my ($c, $client) = @{$_[0]};
    return $client->request (
      path => ['hatena'],
      method => 'POST',
      body => $input,
      params => \%args,
    )->then (sub {
      my $res = $_[0];
      test {
        is $res->status, 200;
        is $res->body_bytes, $expected;
      } $c;
    });
  } n => 2, name => 'converted';
}

RUN;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <http://www.gnu.org/licenses/>.

=cut
