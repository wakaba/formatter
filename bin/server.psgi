# -*- Perl -*-
use strict;
use warnings;
use Wanage::HTTP;
use Warabe::App;
BEGIN { $INC{"Text/VimColor.pm"} = 1 }
use Text::Hatena;

my $ClientOrigins = {map { $_ => 1 } split /\s+/, $ENV{APP_CLIENT_ORIGINS} // ''};

{
  package TheUserAgent;

  sub get ($$) {
    my ($self, $url) = @_;
    return bless {url => $url}, 'TheResponse';
  } # get

  package TheResponse;
  use Web::Encoding;

  sub content ($) {
    return encode_web_utf8 sprintf "<title>%s</title>", $_[0]->{url};
  } # content
  *decoded_content = \&content;

  use Text::Hatena::Embed;
  no warnings 'redefine';
  *Text::Hatena::Embed::render = sub { return undef };
}

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    warn sprintf "ACCESS: [%s] %s %s FROM %s %s\n",
        scalar gmtime,
        $app->http->request_method, $app->http->url->stringify,
        $app->http->client_ip_addr->as_text,
        $app->http->get_request_header ('User-Agent') // '';

    $app->http->set_response_header
        ('Strict-Transport-Security',
         'max-age=10886400; includeSubDomains; preload');

    my $path = $app->path_segments;
    if (@$path == 1 and $path->[0] eq 'hatena') {
      return $app->throw_error (405)
          unless $app->http->request_method eq 'POST';
      return $app->throw_error (400, reason_phrase => 'Bad origin')
          unless $ClientOrigins->{$app->http->get_request_header ('origin') // ''};
      my $input_ref = $app->http->request_body_as_ref;
      my $parser = Text::Hatena->new
          (use_vim => 0,
           ua => bless {}, 'TheUserAgent');
      $app->http->send_response_body_as_text ($parser->parse ($$input_ref));
      return $app->http->close_response_body;
    } else {
      return $app->throw_error (404);
    }
  });
};

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
