use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/modules/*/lib');
use TestServers;
use Promise;
use Promised::Flow;
use Test::More;
use Test::X1;
use Exporter::Lite;
use Web::Transport::ConnectionClient;

our @EXPORT = grep { not /^\$/ }
    @Test::More::EXPORT,
    @Test::X1::EXPORT,
    @Promised::Flow::EXPORT;

my $URL;

push @EXPORT, 'RUN';
sub RUN () {
  my ($stop, $completed);
  TestServers->servers (
    onurl => sub {
      $URL = $_[0];
    },
  )->then (sub {
    ($stop, $completed) = @{$_[0]};
  })->to_cv->recv;
  run_tests;
  $stop->()->to_cv->recv;
  $completed->()->to_cv->recv;
} # RUN

push @EXPORT, 'Test';
sub Test (&;%) {
  my $code = shift;
  &Test::X1::test (sub {
    my $c = shift;
    my $client = Web::Transport::ConnectionClient->new_from_url ($URL);
    promised_cleanup {
      done $c;
      undef $c;
    } promised_cleanup {
      return $client->close;
    } Promise->resolve ([$c, $client])->then ($code)->catch (sub {
      my $error = $_[0];
      test {
        ok 0;
        is $error, undef;
      } $c;
    });
  }, @_);
} # Test

1;

=head1 LICENSE

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

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
