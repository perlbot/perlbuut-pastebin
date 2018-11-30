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


sub get_eval {
    my ($self, $paste_id, $code, $langs, $callback) = @_;
    print "Entering\n";

    if (@$langs == 1 && $langs->[0] eq "evalall") {
      $langs = [qw/perl perl5.28 perl5.26 perl5.26t perl5.24 perl5.22 perl5.20 perl5.18 perl5.16 perl5.14 perl5.12 perl5.10 perl5.8 perl5.6/];
    }

    use Data::Dumper;
    print "Languages! ", Dumper($langs);
    if ($paste_id && (my $cached = $memd->get($paste_id))) {
      $callback->($cached);
    } else {
      # connect to server
      my %futures;

      my $server = $self->eval_connect(sub {
        my ($loop, $err, $stream) = @_;

        my $reader = $self->get_eval_reader($stream);
        my %output;

        for my $lang (@$langs) {
          if ($lang eq 'text') {
            $callback->("");
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
                $memd->set($paste_id, \%output) if ($paste_id);
                print "Returning output to delay\n";
                use Data::Dumper;
                print Dumper(\%output);
                $callback->(\%output);
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
