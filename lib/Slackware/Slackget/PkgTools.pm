package Slackware::Slackget::PkgTools;

use warnings;
use strict;

require Slackware::Slackget::Status ;
use File::Copy ;

use constant {
	PKG_INSTALL_OK				=>	0x43001,
	PKG_UPGRADE_OK				=>	0x43003,
	PKG_REMOVE_OK				=>	0x43005,
	PKG_INSTALL_FAIL				=>	0x43002,
	PKG_UPGRADE_FAIL				=>	0x43004,
	PKG_REMOVE_FAIL				=>	0x43006,
	PKG_NOT_FOUND_INSTALL_FAIL	=>	0x43007,
	PKG_NOT_FOUND_UPGRADE_FAIL	=>	0x43008,
	PKG_NOT_FOUND_REMOVE_FAIL	=>	0x43009,
	PKG_UNKNOWN_FAIL			=>	0x43010,
};

=head1 NAME

Slackware::Slackget::PkgTools - A wrapper for the pkgtools action(installpkg, upgradepkg and removepkg)

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

This class is anoter wrapper for slack-get. It encapsulates the pkgtools system call.

    use Slackware::Slackget::PkgTools;

    my $pkgtool = Slackware::Slackget::PkgTools->new($config);
    $pkgtool->install($package1);
    $pkgtool->remove($package_list);
    foreach (@{$packagelist->get_all})
    {
    	print "Status for ",$_->name," : ",$_->status()->to_string,"\n";
    }
    $pkgtool->upgrade($package_list);

=cut

sub new
{
	my ($class,$config,%args) = @_ ;
	return undef if(!defined($config) && ref($config) ne 'Slackware::Slackget::Config') ;
	my $self={};
	$self->{CONF} = $config ;
	$self->{SUCCESS_STATUS} = {
		PKG_INSTALL_OK	=> "Package have been installed successfully.\n",
		PKG_UPGRADE_OK	=> "Package have been upgraded successfully.\n",
		PKG_REMOVE_OK	=> "Package have been removed successfully.\n",
	};
	$self->{ERROR_STATUS}={
		PKG_NOT_FOUND_INSTALL_FAIL	=> "Can't install package : new package not found in the cache.\n",
		PKG_NOT_FOUND_REMOVE_FAIL	=> "Can't remove package : no such package installed.\n",
		PKG_NOT_FOUND_UPGRADE_FAIL	=> "Can't upgrade package : new package not found in the cache.\n",
		PKG_INSTALL_FAIL				=> "Can't install package : an error occured during $self->{CONF}->{common}->{pkgtools}->{'installpkg-binary'} system call\n",
		PKG_REMOVE_FAIL				=> "Can't remove package : an error occured during $self->{CONF}->{common}->{pkgtools}->{'removepkg-binary'} system call\n",
		PKG_UPGRADE_FAIL				=> "Can't upgrade package : an error occured during $self->{CONF}->{common}->{pkgtools}->{'upgradepkg-binary'} system call\n",
		PKG_UNKNOWN_FAIL => "An error occured in the Slackware::Slackget::PkgTool class (during installpkg, upgradepkg or removepkg) but the class is unable to understand the error.\n",
	};
	$self->{DATA} = {
		'info-output' => undef,
		'connection-id' => 0,
		'fake_mode' => 0,
	};
	$self->{DATA}->{'fake_mode'} = $args{'fake_mode'} if(defined($args{'fake_mode'}));
	bless($self,$class);
	
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

Take a Slackware::Slackget::Config object as argument :

	my $pkgtool = new Slackware::Slackget::PkgTool ($config);
=cut

sub _send_info
{
	my ($self,$action,$pkg) = @_;
	my $client=0;
	return 0 unless(defined($self->{DATA}->{'info-output'}) && $self->{DATA}->{'info-output'});
	$client = $self->{DATA}->{'info-output'} if(defined($self->{DATA}->{'info-output'}) && $self->{DATA}->{'info-output'});
	#print for debug purpose
	print "[Slackware::Slackget::PkgTools::DEBUG] info:$self->{DATA}->{'connection-id'}:2:progress:file=$pkg;state=now$action\n";
	
	print $client->put("info:$self->{DATA}->{'connection-id'}:2:progress:file=$pkg;state=now$action\n") if($client && defined($self->{DATA}->{'connection-id'}) && $self->{DATA}->{'connection-id'});
}

=head1 FUNCTIONS

Slackware::Slackget::PkgTools methods used the followings status :

		0 : Package have been installed successfully.
		1 : Package have been upgraded successfully.
		2 : Package have been removed successfully.
		3 : Can't install package : new package not found in the cache.
		4 : Can't remove package : no such package installed.
		5 : Can't upgrade package : new package not found in the cache.
		6 : Can't install package : an error occured during <installpkg-binary /> system call
		7 : Can't remove package : an error occured during <removepkg-binary /> system call
		8 : Can't upgrade package : an error occured during <upgradepkg-binary /> system call
		9 : Package scheduled for install on next reboot.
		10 : An error occured in the Slackware::Slackget::PkgTool class (during installpkg, upgradepkg or removepkg) but the class is unable to understand the error.

=head2 install

Take a single Slackware::Slackget::Package object or a single Slackware::Slackget::PackageList as argument and call installpkg on all this packages.
Return 1 or undef if an error occured. But methods from the Slackware::Slackget::PkgTools class don't return on the first error, it will try to install all packages. Additionnally, for each package, set a status.

	$pkgtool->install($package_list);

=cut

sub install {
	 
	sub _install_package
	{
		my ($self,$pkg) = @_;
		my $status = new Slackware::Slackget::Status (success_codes => $self->{SUCCESS_STATUS}, error_codes => $self->{ERROR_STATUS});
		#$self->{CONF}->{common}->{'update-directory'}/".$server->shortname."/cache/
# 		print "[Slackware::Slackget::PkgTools::_install_package DEBUG] try to install package ",$pkg->get_id,"\n";
		if($pkg->getValue('install_later'))
		{
# 			print "[Slackware::Slackget::PkgTools::_install_package DEBUG] package ",$pkg->get_id," will be installed later.\n";
			mkdir "/tmp/slack_get_boot_install" unless( -e "/tmp/slack_get_boot_install") ;
		}
		elsif( -e "$self->{CONF}->{common}->{'update-directory'}/package-cache/".$pkg->get_id.".tgz")
		{
			$self->_send_info('install',$pkg->get_id());
# 			print "[Slackware::Slackget::PkgTools::_install_package DEBUG] log file : $self->{CONF}->{common}->{'log'}->{'log-file'}\n";
			if(system("2>>$self->{CONF}->{common}->{'log'}->{'log-file'} $self->{CONF}->{common}->{pkgtools}->{'installpkg-binary'} $self->{CONF}->{common}->{'update-directory'}/package-cache/".$pkg->get_id.".tgz")==0)
			{
# 				print "[Slackware::Slackget::PkgTools::_install_package DEBUG] package ",$pkg->get_id," have been correctly installed\n";
				$status->current(PKG_INSTALL_OK);
				return $status ;
			}
			else
			{
# 				print "[Slackware::Slackget::PkgTools::_install_package DEBUG] package ",$pkg->get_id," have NOT been correctly installed\n";
				$status->current(PKG_INSTALL_FAIL);
				return $status ;
			}
			
		}
		else
		{
# 			print "[Slackware::Slackget::PkgTools::_install_package DEBUG] package ",$pkg->get_id," can't be installed.\n";
			$status->current(PKG_NOT_FOUND_INSTALL_FAIL);
			return $status ;
		}
	}
	my ($self,$object) = @_;
	if(ref($object) eq 'Slackware::Slackget::PackageList')
	{
# 		print "[install] Do the job for a Slackware::Slackget::PackageList\n";
		foreach my $pack ( @{ $object->get_all() })
		{
# 			print "[install] sending ",$pack->get_id," to _install_package.\n";
			$pack->status($self->_install_package($pack));
		}
# 		print "[install] end of the install loop.\n";
	}
	elsif(ref($object) eq 'Slackware::Slackget::Package')
	{
# 		print "[install] Do the job for a Slackware::Slackget::Package '$object'\n";
		$object->status($self->_install_package($object));
	}
	else
	{
		return undef;
	}
# 	print "[Slackware::Slackget::PkgTools DEBUG] all job processed.\n";
}

=head2 upgrade

Take a single Slackware::Slackget::Package object or a single Slackware::Slackget::PackageList as argument and call upgradepkg on all this packages.
Return 1 or undef if an error occured. But methods from the Slackware::Slackget::PkgTools class don't return on the first error, it will try to install all packages. Additionnally, for each package, set a status.

	$pkgtool->install($package_list) ;

=cut

sub upgrade {
	
	sub _upgrade_package
	{
		my ($self,$pkg) = @_;
		my $status = new Slackware::Slackget::Status (success_codes => $self->{SUCCESS_STATUS}, error_codes => $self->{ERROR_STATUS});
		#$self->{CONF}->{common}->{'update-directory'}/".$server->shortname."/cache/
		if( -e "$self->{CONF}->{common}->{'update-directory'}/package-cache/".$pkg->get_id.".tgz")
		{
			$self->_send_info('upgrade',$pkg->get_id());
# 			print "\tTrying to upgrade package: $self->{CONF}->{common}->{'update-directory'}/package-cache/".$pkg->get_id.".tgz\n";
			if(system("2>>$self->{CONF}->{common}->{'log'}->{'log-file'} $self->{CONF}->{common}->{pkgtools}->{'upgradepkg-binary'} $self->{CONF}->{common}->{'update-directory'}/package-cache/".$pkg->get_id.".tgz")==0)
			{
				$status->current(PKG_UPGRADE_OK);
				return $status ;
			}
			else
			{
				$status->current(PKG_UPGRADE_FAIL);
				return $status ;
			}
		}
		else
		{
			$status->current(PKG_NOT_FOUND_UPGRADE_FAIL);
			return $status ;
		}
	}
	my ($self,$object) = @_;
	if(ref($object) eq 'Slackware::Slackget::PackageList')
	{
# 		print "Do the job for a Slackware::Slackget::PackageList\n";
		foreach my $pack ( @{ $object->get_all() })
		{
			$pack->status($self->_upgrade_package($pack));
		}
	}
	elsif(ref($object) eq 'Slackware::Slackget::Package')
	{
# 		print "Do the job for a Slackware::Slackget::Package\n";
		$object->status($self->_upgrade_package($object));
	}
	else
	{
		return undef;
	}
}

=head2 remove

Take a single Slackware::Slackget::Package object or a single Slackware::Slackget::PackageList as argument and call installpkg on all this packages.
Return 1 or undef if an error occured. But methods from the Slackware::Slackget::PkgTools class don't return on the first error, it will try to install all packages. Additionnally, for each package, set a status. 

	$pkgtool->remove($package_list);

=cut

sub remove {
	
	sub _remove_package
	{
		my ($self,$pkg) = @_;
		my $status = new Slackware::Slackget::Status (success_codes => $self->{SUCCESS_STATUS}, error_codes => $self->{ERROR_STATUS});
		#$self->{CONF}->{common}->{'update-directory'}/".$server->shortname."/cache/
		if( -e "$self->{CONF}->{common}->{'packages-history-dir'}/".$pkg->get_id)
		{
			$self->_send_info('remove',$pkg->get_id());
# 			print "\tTrying to remove package: ".$pkg->get_id."\n";
			# TODO: the error output is not logged anymore in the PkgTools calls. It must be fixed.
			if(system("$self->{CONF}->{common}->{pkgtools}->{'removepkg-binary'} ".$pkg->get_id)==0)
			{
				print "[Slackware::Slackget::PkgTools] (removepkg) setting (success) status ",PKG_REMOVE_OK,"\n";
				$status->current(PKG_REMOVE_OK);
				return $status ;
			}
			else
			{
				print "[Slackware::Slackget::PkgTools] (removepkg) setting (failed) status ",PKG_REMOVE_FAIL,"\n";
				$status->current(PKG_REMOVE_FAIL);
				return $status ;
			}
		}
		else
		{
			print "[Slackware::Slackget::PkgTools] (removepkg) setting (fail) status ",PKG_NOT_FOUND_REMOVE_FAIL,"\n";
			$status->current(PKG_NOT_FOUND_REMOVE_FAIL);
			return $status ;
		}
	}
	my ($self,$object) = @_;
	if(ref($object) eq 'Slackware::Slackget::PackageList')
	{
# 		print "Do the job for a Slackware::Slackget::PackageList\n";
		foreach my $pack ( @{ $object->get_all() })
		{
			$pack->status($self->_remove_package($pack));
		}
	}
	elsif(ref($object) eq 'Slackware::Slackget::Package')
	{
# 		print "Do the job for a Slackware::Slackget::Package\n";
		$object->status($self->_remove_package($object));
	}
	else
	{
		return undef;
	}
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

1; # End of Slackware::Slackget::PkgTools
