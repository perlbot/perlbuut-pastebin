package App::Model::Eval;

use strict;
use warnings;
use v5.22;

use Mojo::Base '-base';

use App::EvalServerAdvanced::Protocol;

use App::Config;
use App::Memcached;

has cfg => sub {App::Config::get_config('evalserver')}; 

sub get_eval {
    my ($self, $paste_id, $code, $lang) = @_;
   
    if ($paste_id && (my $cached = $memd->get($paste_id))) {
        return $cached;
    } else {

        $lang //= "perl";
        return undef if ($lang eq 'text');

        my $str = eval {$self->do_singleeval($lang, $code)};

        return "ERROR: evalserver broken: $@" if $@;

        $memd->set($paste_id, $str) if ($paste_id);

        return $str;
    }
}

sub do_singleeval {
  my ($self, $type, $code) = @_;

  my $socket = IO::Socket::INET->new(PeerAddr => $self->cfg->{server} //'localhost', PeerPort => $self->cfg->{port} //14401)
    or die "error: cannot connect to eval server";

  my $eval_obj = {language => $type, files => [{filename => '__code', contents => $code, encoding => "utf8"}], prio => {pr_realtime=>{}}, sequence => 1, encoding => "utf8"};

  $socket->autoflush(1);
  print $socket encode_message(eval => $eval_obj);

  my $buf = '';
  my $data = '';
  my $resultstr = "Failed to read a message";

  my $message = $self->read_message($socket);

  if (ref($message) =~ /Warning$/) {
    return $message->message;
  } else {
    return $message->get_contents;
  }
}


sub read_message {
  my ($self, $socket) = @_;

  my $header;
  $socket->read($header, 8) or die "Couldn't read from socket";

  my ($reserved, $length) = unpack "NN", $header;

  die "Invalid packet" unless $reserved == 1;

  my $buffer;
  $socket->read($buffer, $length) or die "Couldn't read from socket2";

  my ($res, $message, $nbuf) = decode_message($header . $buffer);


  die "Data left over in buffer" unless $nbuf eq '';
  die "Couldn't decode packet" unless $res;

  return $message;
}


1;
