package TestServers;
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use Promised::Command;
use Promised::Command::Signals;
use Web::URL;
use Web::Transport::ConnectionClient;

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;

{
  use Socket;
  my $EphemeralStart = 1024;
  my $EphemeralEnd = 5000;

  sub is_listenable_port ($) {
    my $port = $_[0];
    return 0 unless $port;
    
    my $proto = getprotobyname('tcp');
    socket(my $server, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
    setsockopt($server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
    bind($server, sockaddr_in($port, INADDR_ANY)) || return 0;
    listen($server, SOMAXCONN) || return 0;
    close($server);
    return 1;
  } # is_listenable_port

  my $using = {};
  sub find_listenable_port () {
    for (1..10000) {
      my $port = int rand($EphemeralEnd - $EphemeralStart);
      next if $using->{$port}++;
      return $port if is_listenable_port $port;
    }
    die "Listenable port not found";
  } # find_listenable_port
}

sub web ($%) {
  my ($port, %args) = @_;
  my $command = Promised::Command->new
      ([$RootPath->child ('perl'), $RootPath->child ('bin/sarze-server.pl'), $port]);
  my $stop = sub {
    $command->send_signal ('TERM');
    return $command->wait;
  }; # $stop
  my ($ready, $failed);
  my $p = Promise->new (sub { ($ready, $failed) = @_ });
  $command->run->then (sub {
    $command->wait->then (sub {
      $failed->($_[0]);
    });
    my $origin = Web::URL->parse_string (qq<http://localhost:$port>);
    return promised_wait_until {
      my $client = Web::Transport::ConnectionClient->new_from_url ($origin);
      return $client->request (path => ['robots.txt'])->then (sub {
        return not $_[0]->is_network_error;
      });
    } timeout => 60*2;
  })->then (sub {
    $ready->([$stop, $command->wait]);
  }, sub {
    my $error = $_[0];
    return $stop->()->catch (sub {
      warn "ERROR: $_[0]";
    })->then (sub { $failed->($error) });
  });
  return $p;
} # web

sub servers ($%) {
  shift;
  my %args = @_;
  my $port = $args{port} ? $args{port} : find_listenable_port;
  my $url = Web::URL->parse_string ("http://localhost:$port");
  return Promise->all ([
    web ($port),
    Promise->resolve ($url)->then ($args{onurl})->then (sub { [] }),
  ])->then (sub {
    my $stops = $_[0];
    my @stopped = grep { defined } map { $_->[1] } @$stops;
    my @signal;

    my $stop = sub {
      my $cancel = $_[0] || sub { };
      $cancel->();
      @signal = ();
      return Promise->all ([map {
        my ($stop) = @$_;
        Promise->resolve->then ($stop)->catch (sub {
          warn "$$: ERROR: $_[0]";
        });
      } grep { defined } @$stops]);
    }; # $stop

    push @signal, Promised::Command::Signals->add_handler (INT => $stop);
    push @signal, Promised::Command::Signals->add_handler (TERM => $stop);
    push @signal, Promised::Command::Signals->add_handler (KILL => $stop);

    return [$stop, sub {
      @signal = ();
      return Promise->all ([map {
        $_->catch (sub {
          warn "$$: ERROR: $_[0]";
        });
      } @stopped])
    }];
  });
} # servers

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
