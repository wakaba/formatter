use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use Tests;
use Web::Encoding;

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
  ["[http://bad.foo.test/aa:title]", qq{<p><a href="http://bad.foo.test/aa" data-hatena-embed="title">http://bad.foo.test/aa</a></p>\n}],
  ["[https://aba.test/aew43aat33333:embed]", qq{<p><a href="https://aba.test/aew43aat33333" data-hatena-embed="">https://aba.test/aew43aat33333</a></p>\n}],
  ["[https://twitter.com/bukkenfan/status/836562615081947136:embed]", qq{<p><a href="https://twitter.com/bukkenfan/status/836562615081947136" data-hatena-embed="">https://twitter.com/bukkenfan/status/836562615081947136</a></p>\n}],
  [qq{>|js|
function abc () { return x }
||<}, qq{<pre class="code lang-js" data-lang="js">function abc () { return x }</pre>}],
  [qq{id:foo}, qq{<p><a href="https://profile.hatena.ne.jp/foo/">id:foo</a></p>\n}],
  [qq{id:foo}, qq{<p><a href="https://foo/bar/foo/">id:foo</a></p>\n}, urlbase => q<https://foo/bar/>],
  [qq{[[foo]]}, qq{<p><a href="https://d.hatena.ne.jp/keyword/foo" data-hatena-keyword="foo">foo</a></p>\n}],
  [qq{[[foo]]}, qq{<p><a href="https://hoge.test/foo/bar/?a=foo" data-hatena-keyword="foo">foo</a></p>\n}, keyword_url_prefix => "https://hoge.test/foo/bar/?a="],
  [qq{\x{42444}}, qq{<p>\x{42444}</p>\n}],
  [qq{[amazon:abc]}, q{<p><a href="https://www.amazon.co.jp/exec/obidos/external-search?mode=blended&tag=Xadz1&keyword=abc">amazon:abc</a></p>
}, amazonid => "Xadz1"],
  [q{map:31:52}, q{<p><hatena-map lat="31" lon="52"></hatena-map></p>
}],
  [q{http://www.nicovideo.jp/watch/sm9:movie}, '<p><a href="http://www.nicovideo.jp/watch/sm9" data-hatena-embed="movie">http://www.nicovideo.jp/watch/sm9</a></p>
'],
  [q{https://foo.bar/test:detail}, qq{<p><a href="https://foo.bar/test" data-hatena-embed="httpdetail">https://foo.bar/test</a></p>\n}],
  [q{https://foo.bar/test:barcode}, qq{<p><a href="https://foo.bar/test" class="http-barcode" data-hatena-embed="barcode">https://foo.bar/test</a></p>\n}],
  [q{[tex:a^b + c < 1]}, qq{<p><hatena-tex>a^b + c &lt; 1</hatena-tex></p>\n}],
) {
  my ($input, $expected, %args) = @$_;
  Test {
    my ($c, $client) = @{$_[0]};
    return $client->request (
      path => ['hatena'],
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
    path => ['hatena'],
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
    path => ['hatena'],
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
