package App::Model::Eval;

use strict;
use warnings;
use v5.22;

use Mojo::Base '-base';

use App::EvalServerAdvanced::Protocol;

use App::Config;
use App::Memcached;
use Future::Mojo;
use Mojo::IOLoop;

has cfg => sub {App::Config::get_config('evalserver')}; 

our $id = 0; # global id count for evals
my %_futures;

sub _adopt_future {
  my ($self, $id, $future) = @_;

  $_futures{$id} = $future;

  $future->on_ready(sub {
    print "Cleaning up $id\n";
    delete $_futures{$id};
  })
}

sub _get_cache {
  my ($key) = @_;
  return unless defined $key;
  return $memd->get($key);
}

my @major_langs = qw/perl perl5.30.0 perl5.28.2 perl5.26.3 perl5.24.4 perl5.22.4 perl5.20.3 perl5.18.4 perl5.16.3 perl5.14.4 perl5.12.5 perl5.10.1 perl5.8.9 perl5.6.2/;
my @full_langs = map {"perl$_"} '', qw/5.30.0 5.28.2 5.28.1 5.28.0 5.26.3 5.26.2 5.26.1 5.26.0 5.24.4 5.24.3 5.24.2 5.24.1 5.24.0 5.22.4 5.22.3 5.22.2 5.22.1 5.22.0 5.20.3 5.20.2 5.20.1 5.20.0 5.18.4 5.18.3 5.18.2 5.18.1 5.18.0 5.16.3 5.16.2 5.16.1 5.16.0 5.14.4 5.14.3 5.14.2 5.14.1 5.14.0 5.12.5 5.12.4 5.12.3 5.12.2 5.12.1 5.12.0 5.10.1 5.10.0 5.8.9 5.8.8 5.8.7 5.8.6 5.8.5 5.8.4 5.8.3 5.8.2 5.8.1 5.8.0 5.6.2 5.6.1 5.6.0/;

sub get_eval {
    my ($self, $paste_id, $code, $langs, $wait, $callback) = @_;
    print "Entering\n";

    if (@$langs == 1 && $langs->[0] eq "evalall") {
      $langs = [@major_langs];
    } elsif (@$langs == 1 && $langs->[0] eq "evaltall") {
      $langs = [map {$_."t"} @major_langs];
    } elsif (@$langs == 1 && $langs->[0] eq "evalrall") {
      $langs = [map {$_, $_."t"} @major_langs];
    } elsif (@$langs == 1 && $langs->[0] eq 'evalyall') {
      $langs = [map {$_, $_."t"} @full_langs];
    }

    use Data::Dumper;
    print "Languages! ", Dumper($langs);
    if ($paste_id && (my $cached = _get_cache($paste_id))) {
      $callback->($cached);
    } else {
      # connect to server
      my %futures;

      my $server = $self->eval_connect(sub {
        my ($loop, $err, $stream) = @_;

        my $reader = $self->get_eval_reader($stream);
        my %output;

        # TODO make running status messages per langs?
        $memd->set($paste_id, {status => 'running', output => {}});

        if (!$wait && @$langs != 1) {
          $callback->({status => 'running', output => {}});
        }

        for my $lang (@$langs) {
          if ($lang eq 'text') {
            $callback->({status => "ready", output => {}});
            return;
          } else {
            my $future = $self->async_eval($stream, $reader, $lang, $code);
            $futures{$lang} = $future;

            $future->on_done(sub {
              my ($out) = @_;

              print "Future is done for $lang\n";

              $output{$lang} = $out;
              delete $futures{$lang};

              print "remaining, ", Dumper(keys %futures);

              if (!keys %futures) { # I'm the last one
                print "Calling memset\n";
                $memd->set($paste_id, {status => 'ready', output => \%output}) if ($paste_id);
                print "Returning output to delay\n";
                use Data::Dumper;
                print Dumper(\%output);
                if ($wait || @$langs == 1) {
                  $callback->({status => "ready", output => \%output});
                }
              } else {
                $memd->set($paste_id, {status => 'running', output => \%output}) if ($paste_id);
              }

            });
          }
        }
      });
    }
}

sub eval_connect {
  my ($self, $cb) = @_;

  my $loop = Mojo::IOLoop->singleton;

  my $socket = $loop->client({address => $self->cfg->{server} // 'localhost', port => $self->cfg->{port} // 14401}, $cb);

  return $socket;
}

sub async_eval {
  my ($self, $stream, $reader, $lang, $code) = @_;

  my $loop = Mojo::IOLoop->singleton;
  my $future = Future::Mojo->new($loop);

  my $seq = $id++;

  # try to fix bash?
  $code =~ s/\r//g;

  $self->_adopt_future($seq, $future);
  my $eval_obj = {language => $lang, 
                 files => [
                   {filename => '__code', contents => $code, encoding => "utf8"}
                   ], 
                 prio => {pr_realtime => {}}, 
                 sequence => $seq, 
                 encoding => "utf8"};

  use Data::Dumper;
  print Dumper($eval_obj);

  my $message = encode_message(eval => $eval_obj);

  $reader->($seq, $future);
  $stream->write($message);

  return ($seq => $future);
}

sub get_eval_reader {
  my ($self, $stream) = @_;

  my %futures;
  my %warnings;

  my $buf;
  my $out;

  $stream->on(read => sub {
    my ($stream, $bytes) = @_;

    print "Reading bytes\n";

    $buf = $buf . $bytes;
    my ($res, $message, $nbuf);
    do {
      ($res, $message, $nbuf) = decode_message($buf);
      $buf = $nbuf;
      print Dumper($message);

      if ($message) {

        my $type = ref ($message);
        $type =~ s/^App::EvalServerAdvanced::Protocol:://;

        my $seq = $message->sequence;

        if ($type eq 'Warning') {
          push @{$warnings{$seq}}, $message->message;
          $futures{$seq}->done($message->message);
        } elsif ($type eq 'EvalResponse') {
          print "Got eval response for $seq\n";
          my $output = $message->get_contents;

          my $warnings = join ' ', @{$warnings{$seq} || []};

          $futures{$seq}->done($output);
          print "Future is done: $output\n";
        }
      };

    } while ($res);

    return 0;
  });

  return sub {
    my ($seq, $future) = @_;
    print "Registering $seq\n";
    $futures{$seq} = $future;
  }
}

1;
