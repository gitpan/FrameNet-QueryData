package FrameNet::QueryData;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '0.02';

use Carp;
use warnings;
use strict;
use Storable;
use XML::TreeBuilder;
use XML::XPath;
use File::Spec;
use Data::Dumper;
#use Class::MethodMaker 
#  [ scalar => [ { '*_reset' => undef,
#		  '*_clear' => undef }, qw / fnhome 
#					     file_frames_xml
#					     file_frrelation_xml
#					     verbose 
#					     cache / ],
#  ];

sub new {
  my $class = shift;
  my $self = {};

  $class = ref $class || $class;

  bless $self, $class;
  
  my %params = @_;

  ##############
  ### FNHOME ###
  ##############
  # precedence: parameter, environment variable
  if (defined $params{-fnhome}) {
    $self->fnhome($params{-fnhome});
  } elsif (defined $ENV{FNHOME}) {
    $self->fnhome($ENV{FNHOME});
  } else {
      carp "FrameNet could not be found. Did you set \$FNHOME?\n";
    
  }

  ###############
  ### VERBOSE ###
  ###############
  if (defined $params{-verbose}) {
    $self->verbose($params{-verbose})
  } else {
    # Default: No output
    $self->verbose(0);
  };

  # Currently no cache system available
  # $self->cache(0);
  # $self->{VCACHE} = 0.01;
  
  my $infix = "xml";
  $infix = "frXML" if (-e File::Spec->catfile(($self->fnhome,"frXML"),
					      "frames.xml"));
  $self->file_frames_xml(File::Spec->catfile(($self->fnhome,$infix),
					     "frames.xml"));
  $infix = "xml" if (-e File::Spec->catfile(($self->fnhome,"xml"),
					      "frRelation.xml"));
  $self->file_frrelation_xml(File::Spec->catfile(($self->fnhome,$infix),
						 "frRelation.xml"));
  
  # no cache in this version
  # $self->{cachefilename} = File::Spec->catfile((File::Spec->tmpdir),(defined $ENV{'USER'}?$ENV{'USER'}:"user")."-FrameNet-QueryData-".$self->{VCACHE}.".dat");

  return $self;
}

sub fnhome {
    my ($self, $fnhome) = @_;
    $self->{'fnhome'} = $fnhome if (defined $fnhome);
    return $self->{'fnhome'};
}

sub verbose {
    my ($self, $verbose) = @_;
    $self->{'verbose'} = $verbose if (defined $verbose);
    return $self->{'verbose'};
}

sub frame {
  my ($self, $framename) = @_;
  return {} if (not defined $framename);
  my $ret = {};
  $ret->{'name'} = $framename;
  $self->parse;
  $ret->{'lus'} = $self->_lu_part_of_frame($framename);
  $ret->{'fes'} = $self->_fe_part_of_frame($framename);
  return $ret;
};

sub related_frames {
  my ($self, $framename, $relation) = @_;
  $self->xparse;
  return $self->{rels}->{$relation}->{$framename};  
};

sub related_inv_frames {
  my ($self, $framename, $relation) = @_;
  $self->xparse;
  return $self->{rels}->{$relation}->{'inverse'}->{$framename};  
};

sub _fe_part_of_frame {
  my ($self, $framename) = @_;
  my $partnodes = $self->_part_of_frame($framename, 'fe');
  my $ret = [];
  foreach my $pa (@$partnodes) {
    push(@$ret, { 'name' => $pa->find('@name')->string_value,
		  'ID' => $pa->find('@ID')->string_value,
		  'abbrev' => $pa->find('@abbrev')->string_value,
		  'coreType' => $pa->find('@coreType')->string_value });
  }
  return $ret;
};


sub _lu_part_of_frame {
  my ($self, $framename) = @_;
  my $partnodes = $self->_part_of_frame($framename, 'lexunit');
  my $ret = [];
  foreach my $pa (@$partnodes) {
    push(@$ret, { 'name' => $pa->find('@name')->string_value,
		  'ID' => $pa->find('@ID')->string_value,
		  'pos' => $pa->find('@pos')->string_value,
		  'status' => $pa->find('@status')->string_value,
		  'lemmaId' => $pa->find('@lemmaId')->string_value });
  }
  return $ret;
};

sub _part_of_frame {
  my ($self, $framename, $part) = @_;
  $self->parse;
  my @parts = $self->{xtree}->
    find('//frames/frame[@name="'.$framename.'"]/'.$part.'s/'.$part)->
      get_nodelist;
  return \@parts;
}

sub related {
  my $self = shift;
  my ($f1,$f2) = @_;

  $self->xparse;

  foreach my $relname (keys %{$self->{'rels'}}) {
      #print STDERR "Checking ".$relname."\n";
      #print STDERR Dumper($self->{'rels'}{'inverse'}{$relname}{$f2});
      return $relname if (grep(/$f2/, @{$self->{'rels'}{$relname}{$f1}}) or
		   grep(/$f1/, @{$self->{'rels'}{$relname}{$f2}}));
  };
  return 0;
  
};

sub transitive_related {
    my $self = shift;
    my ($frame1, $frame2) = @_;

    $self->xparse;

    foreach my $relname (keys %{$self->{'rels'}}) {
	if (grep(/$frame2/, @{$self->{'rels'}{$relname}{$frame1}}) or
	    grep(/$frame1/, @{$self->{'rels'}{$relname}{$frame2}})) {
	    #print STDERR $relname;

	    return 1;
	}
	foreach my $f (@{$self->{'rels'}{$relname}{$frame1}},
		       @{$self->{'rels'}{$relname}{$frame2}}) {
	    if ($self->transitive_related($frame1, $f)) {
		#print STDERR $f."\n";
		return 1;
	    }
	}
    }
    return 0;
}

sub path_related {
    my $self = shift;
    my $frame1 = shift;
    my $frame2 = shift;
    my @path = @_;

    $self->xparse;
    #print STDERR "$frame1 vs. $frame2 ".join(', ', @path)."\n";
    if (@path == 0) {
	return ($frame1 eq $frame2);
    }

    my $rel = shift(@path);

    foreach my $f (@{$self->{'rels'}{$rel}{$frame1}}) {
	return 1 if ($f eq $frame2);
	return 1 if ($self->path_related($f, $frame2, @path));
    };
    
    foreach my $f (@{$self->{'rels'}{$rel}{'inverse'}{$frame1}}) {
	return 1 if ($f eq $frame2);
	return 1 if ($self->path_related($f, $frame2, @path));
    };

    return 0;
}

sub dumpout {
  my $self = shift;
  $self->xparse;
  print Dumper($self->{rels});
};

sub xparse {
  my $self = shift;
  if (! defined $self->{'xp'}) {
    print STDERR "Parsing XML file (frRelation.xml)\n" if ($self->verbose > 0);
    $self->{'xp'} = XML::XPath->new(filename => $self->file_frrelation_xml);
    
    foreach my $frame_relation ($self->{'xp'}->find("//frame-relation-type/frame-relations/frame-relation")->get_nodelist) {
      
      my $relation_type = $frame_relation->find('../../@name')->string_value;
      
      my $super = $frame_relation->find('@superFrameName')->string_value;
      my $sub = $frame_relation->find('@subFrameName')->string_value;
      
      push(@{$self->{rels}->{$relation_type}->{$sub}},$super);
      #      if (! grep(/$super/,@{$self->{rels}->{$relation_type}->{$sub}}));
      push(@{$self->{rels}->{$relation_type}->{'inverse'}->{$super}},$sub);
      #      if (! grep(/$super/,@{$self->{rels}->{$relation_type}->{'inverse'}->{$super}}));
    };
  };
};

sub file_frames_xml {
    my ($self, $fname) = @_;
    $self->{'file_frames_xml'} = $fname if (defined $fname);
    return $self->{'file_frames_xml'};
}

sub file_frrelation_xml {
    my ($self, $fname) = @_;
    $self->{'file_frrelation_xml'} = $fname if (defined $fname);
    return $self->{'file_frrelation_xml'};
}

sub parse {
   my $self = shift;
   if (not (defined $self->{xtree})) {
     print STDERR "Parsing XML file (frames.xml)\n" if ($self->verbose > 0);
     $self->{xtree} = XML::XPath->new(filename => $self->file_frames_xml);
   };
};

sub frames {
   my $self = shift;
   $self->parse;

   my $frames;
   foreach my $frame ($self->{xtree}->find("//frames/frame")->get_nodelist) {
     $frames->{$frame->find('@name')->string_value} = 1;
   };
   return (keys %$frames);
 }


=head1 NAME

FrameNet::QueryData - A module for accessing the FrameNet data. 

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use FrameNet::QueryData;

    # The name of the frame
    my $framename = "Getting";

    my $qd = FrameNet::QueryData->new(-fnhome => $ENV{'FNHOME'},
                                      -verbose => 0);
    
    my $frame = $qd->frame($framename);
    # Getting the lexical units
    my $lus = $frame->{'lus'};
    # Getting the frame elements
    my $fes = $frame->{'fes'}

    # Listing the names of all lexical units
    print join(', ', map { $_->{'name'} } @$lus);


=head1 DESCRIPTION

The purpose of this module is to provide an easy access to FrameNet. Its database is organized in large XML files, which are parsed by this module. The module is tested with FrameNet 1.2. Other versions may work, but it can not be guaranteed. 

=head1 METHODS

=over 4

=item new ( -fnhome, -verbose)

The constructor for this class. It can take two arguments: The path to the FrameNet directory and a verbosity level. Both are not mandatory. -fnhome defaults to the environment variable $FNHOME, -verbose defaults to 0 (zero), which means no output. 

=item fnhome ($FNHOME)

Sets and returns the FrameNet home directory. If the argument is given, it will be set to the new value. If the argument is omitted, the value will be returned.

=item verbose ($VERBOSE) 

Sets and returns the verbosity level. If the argument is given, the verbosity level will be set to this new value. If not, the value is returned. 

=item frame ($FRAMENAME)

This method returns a hash containing information for the frame $FRAMENAME. The hash has three elements: 

=over 8

=item name

The name of the frame

=item lus

A list containing all the lexical units of the frame. The lexical units are represented by another hash containing the keys 'name', 'ID', 'pos', 'status' and 'lemmaId'.

=item fes 

A list containg all the frame elements for this frame. The frame elements are represented by a hash containing the keys 'name', 'ID', 'abbrev' and 'coreType'.

=back

=item related_frames ($FRAMENAME, $RELATIONNAME)

This method returns a list of frame names, that are related to $FRAMENAME via the relation $RELATIONNAME. 

=item related_inv_frames ($FRAMENAME, $RELATIONNAME) 

Does the same as L<related_frames ($FRAMENAME, $RELATIONNAME)>, but in the other direction of the relation. Using the relation "Inheritance", you can ask for the superordinated frames for example. 

=item related ( $FRAME1, $FRAME2 )

Checks, if $FRAME1 and $FRAME2 are somehow related. If they are related, the exact name of the relation is returned. Otherwise, a 0 (zero) is returned. Note, that this method is not transitive. 

=item transitive_related ( $FRAME1, $FRAME2 )

Checks, if $FRAME1 and $FRAME2 are somehow related. There is no limit on the maximum number of steps, so this method can be slow. And it will probably run forever, if a frame is related to itself. 

=item path_related ( $FRAME1, $FRAME2, @RELATIONS ) 

With this method, one can check if $FRAME1 and $FRAME2 are related through the given path. The path itself is a list of relations. The method tries to explore all the possiblities along the path, so it is also slow. 

=item frames ( )

Returns a list of all frames that are defined in FrameNet. 

=item file_frames_xml ( $PATH ) 

Can be used to get and set the path to the file frames.xml. To get it, just use it without argument. 

=item file_frrelation_xml ( $PATH ) 

Can be used to get and set the path to the file frrelation.xml. To get, use it without argument. 

=item parse ( )

Internal method.

=item xparse ( )

Internal method.

=back

=head1 AUTHOR

Nils Reiter, C<< <reiter@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-framenet-querydata@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FrameNet-QueryData>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Nils Reiter and Aljoscha Burchardt, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FrameNet::QueryData
