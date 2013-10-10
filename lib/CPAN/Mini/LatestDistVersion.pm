package CPAN::Mini::LatestDistVersion;

use base 'CPAN::Mini';

use strict;
use warnings;

use Parse::CPAN::Packages::Fast;
use CPAN::DistnameInfo;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    if( !$self->{ path_filters } ) {
        $self->{ path_filters } = [];
    }
    elsif( $self->{ path_filters } && ref( $self->{ path_filters } ) ne 'ARRAY') {
        $self->{ path_filters } = [ $self->{ path_filters } ];
    }

    push @{ $self->{ path_filters } }, sub { _filter_latest( $self, @_ ) };

    return $self;
}

sub mirror_indices {
    my $self = shift;
    $self->SUPER::mirror_indices( @_ );

    my $packages = Parse::CPAN::Packages::Fast->new( $self->_scratch_dir . '/modules/02packages.details.txt.gz' );
    $self->{ _latest_dists } = _get_latest_dists( $packages );
}

sub _filter_latest {
    my ( $self, $file ) = @_;
    my $dist = CPAN::DistnameInfo->new( $file );

    return 1 if !$dist || !$dist->distvname; # Skip problem dists, if any
    return 0 if $dist->distvname eq $self->{ _latest_dists }->{ $dist->dist }->distvname;
    return 1;
}

# Slightly modified from Parse::CPAN::Packages::Fast
sub _get_latest_dists {
    my $self = shift;

    my %latest_dist;

    for my $pathname ( keys %{ $self->{ dist_to_pkgs } } ) {
        my $d    = Parse::CPAN::Packages::Fast::Distribution->new( $pathname, $self );
        my $dist = $d->dist;
        next if !defined $dist;
        if ( !exists $latest_dist{ $dist } ) {
            $latest_dist{ $dist } = $d;
        }
        else {
            if ( CPAN::Version->vlt( $latest_dist{ $dist }->version, $d->version ) ) {
                $latest_dist{ $dist } = $d;
            }
        }
    }

    return \%latest_dist;
}

1;

__END__

=head1 NAME

CPAN::Mini::LatestDistVersion - Create a CPAN mirror with only the latest version of each distribution
