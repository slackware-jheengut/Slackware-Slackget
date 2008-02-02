package Slackware::Slackget::Config;

use warnings;
use strict;

$XML::Simple::PREFERRED_PARSER='XML::Parser';
use XML::Simple;

=head1 NAME

Slackware::Slackget::Config - An interface to the configuration file

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class is use to load a configuration file (config.xml) and the servers list file (servers.xml). It only encapsulate the XMLin() method of XML::Simple, there is no accessors or treatment method for this class.
There is only a constructor which take only one argument : the name of the configuration file.

After loading you can acces to all values of the config file in the same way that with XML::Simple.

The only purpose of this class, is to allow other class to check that the config file have been properly loaded.

    use Slackware::Slackget::Config;

    my $config = Slackware::Slackget::Config->new('/etc/slack-get/config.xml') or die "cannot load config.xml\n";
    print "I will use the encoding: $config->{common}->{'file-encoding'}\n";
    print "slack-getd is configured as: $config->{daemon}->{mode}\n" ;

This module need XML::Simple to work.

=cut

=head1 CONSTRUCTOR

=head2 new

The constructor take the config file name as argument.

	my $config = Slackware::Slackget::Config->new('/etc/slack-get/config.xml') or die "cannot load config.xml\n";

=cut

sub new
{
	my ($class,$file) = @_ ;
	return undef unless(-e $file && -r $file);
	my $self= XMLin($file , ForceArray => ['li']) or return undef;
# 	use Data::Dumper;
# 	print Dumper($self);
	return undef unless(defined($self->{common}));
	if(exists($self->{'plugins'}->{'list'}->{'plug-in'}->{'id'}) && defined($self->{'plugins'}->{'list'}->{'plug-in'}->{'id'}))
	{
		my $tmp = $self->{'plugins'}->{'list'}->{'plug-in'};
		delete($self->{'plugins'}->{'list'}->{'plug-in'});
		$self->{'plugins'}->{'list'}->{'plug-in'}->{$tmp->{'id'}} = $tmp;
		delete($self->{'plugins'}->{'list'}->{'plug-in'}->{$tmp->{'id'}}->{'id'});
	}
	if($ENV{SG_DAEMON_DEBUG}){
		require Data::Dumper;
		print Data::Dumper::Dumper( $self ),"\n";
	}
	bless($self,$class);
	return $self;
}

=head2 check_config

Check for some fatal omission or error in the configuration file. Return the number of fatal errors found. Print message on the standard error output.

	my $error_count = $config->check_config ;

=cut

sub check_config
{
	my $self = shift;
	my $fatal = 0;
	print STDERR  "===> Checking for fatal error in the configuration file <===\n";
	print STDERR  "checking for options '<common>'...";
	if(exists($self->{'common'}) && defined($self->{'common'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<update-directory>'...";
	if(exists($self->{'common'}->{'update-directory'}) && defined($self->{'common'}->{'update-directory'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
	}
	print STDERR  "\tchecking for options '<server-list-file>'...";
	if(exists($self->{'common'}->{'server-list-file'}) && defined($self->{'common'}->{'server-list-file'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<packages-history-dir>'...";
	if(exists($self->{'common'}->{'packages-history-dir'}) && defined($self->{'common'}->{'packages-history-dir'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<conf-version>'...";
	if(exists($self->{'common'}->{'conf-version'}) && defined($self->{'common'}->{'conf-version'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	
	print STDERR  "checking for options '<daemon>'...";
	if(exists($self->{'daemon'}) && defined($self->{'daemon'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<pid-file>'...";
	if(exists($self->{'daemon'}->{'pid-file'}) && defined($self->{'daemon'}->{'pid-file'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<installed-packages-list>'...";
	if(exists($self->{'daemon'}->{'installed-packages-list'}) && defined($self->{'daemon'}->{'installed-packages-list'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<build-on-update>'...";
	if(exists($self->{'daemon'}->{'installed-packages-list'}->{'build-on-update'}) && defined($self->{'daemon'}->{'installed-packages-list'}->{'build-on-update'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<build-each>'...";
	if(exists($self->{'daemon'}->{'installed-packages-list'}->{'build-each'}) && defined($self->{'daemon'}->{'installed-packages-list'}->{'build-each'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<update-list>'...";
	if(exists($self->{'daemon'}->{'update-list'}) && defined($self->{'daemon'}->{'update-list'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<build-on-start>'...";
	if(exists($self->{'daemon'}->{'update-list'}->{'build-on-start'}) && defined($self->{'daemon'}->{'update-list'}->{'build-on-start'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<build-each>'...";
	if(exists($self->{'daemon'}->{'update-list'}->{'build-each'}) && defined($self->{'daemon'}->{'update-list'}->{'build-each'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<mode>'...";
	if(exists($self->{'daemon'}->{'mode'}) && defined($self->{'daemon'}->{'mode'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<listenning-port>'...";
	if(exists($self->{'daemon'}->{'listenning-port'}) && defined($self->{'daemon'}->{'listenning-port'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<listenning-adress>'...";
	if(exists($self->{'daemon'}->{'listenning-adress'}) && defined($self->{'daemon'}->{'listenning-adress'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\tchecking for options '<connection-policy>'...";
	if(exists($self->{'daemon'}->{'connection-policy'}) && defined($self->{'daemon'}->{'connection-policy'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<all>'...";
	if(exists($self->{'daemon'}->{'connection-policy'}->{'all'}) && defined($self->{'daemon'}->{'connection-policy'}->{'all'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		$fatal++;
	}
	print STDERR  "\t\tchecking for options '<host>'...";
	if(exists($self->{'daemon'}->{'connection-policy'}->{'host'}) && defined($self->{'daemon'}->{'connection-policy'}->{'host'}))
	{
		print STDERR  "ok\n";
	}
	else
	{
		print STDERR  "no\n";
		if(defined($self->{'daemon'}->{'connection-policy'}->{'all'}) && defined($self->{'daemon'}->{'connection-policy'}->{'all'}->{'allow-connection'}) &&  $self->{'daemon'}->{'connection-policy'}->{'all'}->{'allow-connection'}=~ /no/i)
		{
			print STDERR "** WARNING ** You don't have <host> section in your configuration file and the <all> section forbid connection ! Nobody can connect to your daemon !!!\n";
		}
	}
	
# 	print STDERR  "checking for options ''...";
# 	if(exists($self->{''}) && defined($self->{''}))
# 	{
# 		print STDERR  "ok\n";
# 	}
# 	else
# 	{
# 		print STDERR  "no\n";
# 		$fatal++;
# 	}
# 	print STDERR  "checking for options ''...";
# 	if(exists($self->{''}) && defined($self->{''}))
# 	{
# 		print STDERR  "ok\n";
# 	}
# 	else
# 	{
# 		print STDERR  "no\n";
# 		$fatal++;
# 	}
# 	print STDERR  "\tchecking for options '<>'...";
# 	if(exists($self->{'common'}->{''}) && defined($self->{'common'}->{''}))
# 	{
# 		print STDERR  "ok\n";
# 	}
# 	else
# 	{
# 		print STDERR  "no\n";
# 		$fatal++;
# 	}
# 	print STDERR  "\tchecking for options '<>'...";
# 	if(exists($self->{'common'}->{''}) && defined($self->{'common'}->{''}))
# 	{
# 		print STDERR  "ok\n";
# 	}
# 	else
# 	{
# 		print STDERR  "no\n";
# 		$fatal++;
# 	}
	
	if($fatal)
	{
		print STDERR  "\n\nSTATUS : the configuration file have $fatal fatal problems\n";
	}
	else
	{
		print STDERR  "\n\nSTATUS : the configuration file seems to be good (at least there is no fatal errors...)\n";
	}
	return $fatal;
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Config
