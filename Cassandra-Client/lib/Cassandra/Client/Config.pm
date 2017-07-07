package Cassandra::Client::Config;

use 5.010;
use strict;
use warnings;

use Ref::Util qw/is_plain_arrayref/;

sub new {
    my ($class, $config)= @_;

    my $self= bless {
        anyevent                => 0,
        contact_points          => undef,
        port                    => 9042,
        cql_version             => undef,
        keyspace                => undef,
        compression             => undef,
        default_consistency     => undef,
        max_page_size           => 5000,
        max_connections         => 2,
        timer_granularity       => 0.1,
        request_timeout         => 11,
        warmup                  => 0,
        max_concurrent_queries  => 1000,
        tls                     => 0,

        throttler               => undef,
        command_queue           => undef,
        retry_policy            => undef,
    }, $class;

    if (my $cp= $config->{contact_points}) {
        if (is_plain_arrayref($cp)) {
            @{$self->{contact_points}=[]}= @$cp;
        } else { die "contact_points must be an arrayref"; }
    } else { die "contact_points not specified"; }

    # Booleans
    for (qw/anyevent warmup tls/) {
        if (exists($config->{$_})) {
            $self->{$_}= !!$config->{$_};
        }
    }

    # Numbers
    for (qw/port timer_granularity request_timeout max_connections max_concurrent_queries/) {
        if (defined($config->{$_})) {
            $self->{$_}= 0+ $config->{$_};
        }
    }
    for (qw/max_page_size/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? (0+ $config->{$_}) : undef;
        }
    }

    # Strings
    for (qw/cql_version keyspace compression default_consistency/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? "$config->{$_}" : undef;
        }
    }

    if (exists($config->{throttler})) {
        die "throttler must be a Cassandra::Client::Policy::Throttle::Default"
            unless $config->{throttler}->isa("Cassandra::Client::Policy::Throttle::Default");
        $self->{throttler}= $config->{throttler};
    }
    if (exists($config->{retry_policy})) {
        die "retry_policy must be a Cassandra::Client::Policy::Retry::Default"
            unless $config->{retry_policy}->isa("Cassandra::Client::Policy::Retry::Default");
        $self->{retry_policy}= $config->{retry_policy};
    }
    if (exists($config->{command_queue})) {
        die "command_queue must be a Cassandra::Client::Policy::Queue::Default"
            unless $config->{command_queue}->isa("Cassandra::Client::Policy::Queue::Default");
        $self->{command_queue}= $config->{command_queue};
    }

    $self->{username}= $config->{username};
    $self->{password}= $config->{password};

    return $self;
}

1;
