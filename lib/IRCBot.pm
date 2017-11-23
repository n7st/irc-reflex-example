package IRCBot;

# ABSTRACT: An example IRC bot made with Reflex and Moose

use Data::Printer;
use Moose;
use POE 'Component::IRC';
use Reflex::POE::Session;
use Reflex::Trait::Watched 'watches';

extends 'Reflex::Base';
with    'Reflex::Role::Reactive';

################################################################################

has component => (is => 'ro', isa => 'POE::Component::IRC', lazy_build => 1);

watches poco => (is => 'rw', isa => 'Reflex::POE::Session', role => 'poco');

################################################################################

sub BUILD {
    my $self = shift;

    # Give Reflex a session ID to watch
    $self->poco(Reflex::POE::Session->new({
        sid => $self->component->session_id,
    }));

    # Initialise the connection
    $self->run_within_session(sub {
        $self->component->yield(register => 'all');
        $self->component->yield(connect => {});
    });

    # Finally, run the Reflex event watchers
    return $self->run_all();
}

sub on_poco_irc_001 {
    my $self  = shift;
    my $event = shift;

    # The bot has connected to the network

    # Substitute ##Mike for your own channel(s) here
    my @channels = ('##Mike');

    foreach my $channel (@channels) {
        $self->component->yield(join => $channel);
    }

    return 1;
}

sub on_poco_irc_public {
    my $self  = shift;
    my $event = shift;

    # The bot has received a public message
    my $message = $event->{args}->[2];
    my $channel = $event->{args}->[1]->[0];

    # You can view the content of $event using:
    # p $event;

    # Command example - respond to "!ping" with "Pong!"
    if (lc($event->{args}->[2]) eq '!ping') {
        $self->component->yield('privmsg' => $channel => 'Pong!');
    }

    return 1;
}

################################################################################

sub _build_component {
    my $self = shift;

    # Change UseSSL to 1 and port to 6697 to use SSL
    # To connect to an IRC server using SSL:
    #   - use POE::Component::SSLify
    #   - Change "UseSSL" to 1
    #   - Change "port" to 6697
    return POE::Component::IRC->spawn(
        server   => 'irc.snoonet.org',
        port     => 6667,
        nick     => 'ReflexBot',
        username => 'ReflexBot',
        ircname  => 'ReflexBot',
        debug    => 1,
        UseSSL   => 0,
    );
}

################################################################################

no Moose;
__PACKAGE__->meta->make_immutable();
1;

