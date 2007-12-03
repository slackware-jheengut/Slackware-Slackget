package Slackware::Slackget::Package;

use warnings;
use strict;

require Slackware::Slackget::MD5;
use Data::Dumper;

=head1 NAME

Slackware::Slackget::Package - This class is the internal representation of a package for slack-get 1.0

=head1 VERSION

Version 1.0.1

=cut

our @ISA = qw( Slackware::Slackget::MD5 );
our $VERSION = '1.0.2';

=head1 SYNOPSIS

This module is used to represent a package for slack-get

    use Slackware::Slackget::Package;

    my $package = Slackware::Slackget::Package->new('package-1.0.0-noarch-1');
    $package->setValue('description',"This is a test of the Slackware::Slackget::Package object");
    $package->fill_object_from_package_name();

This class inheritate from Slackware::Slackget::MD5, so you can use :

	$sgo->installpkg($package) if($package->verify_md5);

Isn't it great ?

=head1 CONSTRUCTOR

=head2 new

The constructor take two parameters : a package name, and an id (the namespace of the package like 'slackware' or 'linuxpackages')

	my $package = new Slackware::Slackget::Package ('aaa_base-10.0.0-noarch-1','slackware');

The constructor automatically call the fill_object_from_package_name() method.

You also can pass some extra arguments like that :

	my $package = new Slackware::Slackget::Package ('aaa_base-10.0.0-noarch-1', 'package-object-version' => '1.0.0');

The constructor return undef if the id is not defined.

=cut

sub new
{
	my ($class,$id,%args) = @_ ;
	return undef unless($id);
	my $self={%args};
	$self->{ROOT} = $id ;
	$self->{STATS} = {hw => [], dwc => 0};
	bless($self,$class);
	$self->fill_object_from_package_name();
	return $self;
}

=head1 FUNCTIONS

=head2 merge

This method merge $another_package with $package. WARNING: $another_package will be destroy in the operation (this is a collateral damage ;-), for some dark preocupation of memory.

This method overwrite existing value.

	$package->merge($another_package);

=cut

sub merge {
	my ($self,$package) = @_ ;
	return unless($package);
	foreach (keys(%{$package->{PACK}})){
		$self->{PACK}->{$_} = $package->{PACK}->{$_} ;
	}
	$self->{STATS} = {hw => [@{ $package->{STATS}->{hw} }], dwc => $package->{STATS}->{dwc}} ;
	$package = undef;
}

=head2 is_heavy_word

This method return true (1) if the first argument is an "heavy word" and return false (0) otherwise.

	print "heavy word found !\n" if($package->is_heavy_word($request[$i]));

=cut

sub is_heavy_word
{
	my ($self,$w) = @_ ;
	return unless($w);
	return 1 if($self->{PACK}->{statistics}->{hw} =~ /\Q:$w:\E/);
	return 0;
}

=head2 get_statistic

Return a given statistic about the description of the package. Currently available are : dwc (description words count) and hw (heavy words,  a list of important words).

Those are for the optimisation of the search speed.

=cut

sub get_statistic
{
	my ($self,$w) = @_ ;
	return $self->{PACK}->{statistics}->{$w};
}

=head2 compare_version

This method take another Slackware::Slackget::Package as argument and compare it's version to the current object.

	if( $package->compare_version( $another_package ) == -1 )
	{
		print $another_package->get_id," is newer than ",$package->get_id ,"\n";
	}

Returned code :

	-1 => $package version is lesser than $another_package's one
	0 => $package version is equal to $another_package's one
	1 => $package version is greater than $another_package's one
	undef => an error occured.

=cut

sub compare_version
{
	my ($self,$o_pack) = @_ ;
# 	warn "$o_pack is not a Slackware::Slackget::Package !" if(ref($o_pack) ne 'Slackware::Slackget::Package') ;
	if($o_pack->can('version'))
	{
# 		print "compare_version ",$self->get_id()," v. ",$self->version()," and ",$o_pack->get_id()," v. ",$o_pack->version(),"\n";
		$o_pack->setValue('version','0.0.0') unless(defined($o_pack->version()));
		$self->setValue('version','0.0.0') unless(defined($self->version()));
		my @o_pack_version = split(/\./, $o_pack->version()) ;
		my @self_version = split(/\./, $self->version()) ;
		for(my $k=0; $k<=$#self_version; $k++)
		{
# 			print "\t cmp $self_version[$k] and $o_pack_version[$k]\n";
			$self_version[$k] = 0 unless(defined($self_version[$k]));
			$o_pack_version[$k] = 0 unless(defined($o_pack_version[$k]));
			if($self_version[$k] =~ /^\d+$/ && $o_pack_version[$k] =~ /^\d+$/)
			{
				if($self_version[$k] > $o_pack_version[$k])
				{
# 					print "\t",$self->get_id()," greater than ",$o_pack->get_id(),"\n";
					return 1;
				}
				elsif($self_version[$k] < $o_pack_version[$k])
				{
# 					print "\t",$self->get_id()," lesser than ",$o_pack->get_id(),"\n";
					return -1;
				}
			}
			else
			{
				if($self_version[$k] gt $o_pack_version[$k])
				{
# 					print "\t",$self->get_id()," greater than ",$o_pack->get_id(),"\n";
					return 1;
				}
				elsif($self_version[$k] lt $o_pack_version[$k])
				{
# 					print "\t",$self->get_id()," lesser than ",$o_pack->get_id(),"\n";
					return -1;
				}
			}
		}
# 		print "\t",$self->get_id()," equal to ",$o_pack->get_id(),"\n";
		return 0;
	}
	else
	{
		return undef;
	}
}

=head2 fill_object_from_package_name

Try to extract the maximum informations from the name of the package. The constructor automatically call this method.

	$package->fill_object_from_package_name();

=cut

sub fill_object_from_package_name{
	my $self = shift;
	if($self->{ROOT}=~ /^(.*)-([0-9].*)-(i[0-9]86|noarch)-(\d{1,2})(\.tgz)?$/)
	{
		$self->setValue('name',$1);
		$self->setValue('version',$2);
		$self->setValue('architecture',$3);
		$self->setValue('package-version',$4);
		$self->setValue('package-maintener','Slackware team') if(defined($self->{SOURCE}) && $self->{SOURCE}=~/^slackware$/i);
	}
	elsif($self->{ROOT}=~ /^(.*)-([0-9].*)-(i[0-9]86|noarch)-(\d{1,2})(\w*)(\.tgz)?$/)
	{
		$self->setValue('name',$1);
		$self->setValue('version',$2);
		$self->setValue('architecture',$3);
		$self->setValue('package-version',$4);
# 		$self->setValue('package-maintener',$5) if(!defined($self->getValue('package-maintener')));
	}
	elsif($self->{ROOT}=~ /^(.*)-([^-]+)-(i[0-9]86|noarch)-(\d{1,2})(\.tgz)?$/)
	{
		$self->setValue('name',$1);
		$self->setValue('version',$2);
		$self->setValue('architecture',$3);
		$self->setValue('package-version',$4);
		$self->setValue('package-maintener','Slackware team') if(defined($self->{SOURCE}) && $self->{SOURCE}=~/^slackware$/i);
	}
	elsif($self->{ROOT}=~ /^(.*)-([^-]+)-(i[0-9]86|noarch)-(\d{1,2})(\w*)(\.tgz)?$/)
	{
		$self->setValue('name',$1);
		$self->setValue('version',$2);
		$self->setValue('architecture',$3);
		$self->setValue('package-version',$4);
# 		$self->setValue('package-maintener',$5) if(!defined($self->getValue('package-maintener')));
	}
	else
	{
		$self->setValue('name',$self->{ROOT});
	}
	$self->{STATS}->{hw} = [split(/-/,$self->getValue('name'))];
}

=head2 extract_informations

Extract informations about a package from a string. This string must be a line of the description of a package.

	$package->extract_informations($data);

This method is designe to be called by the Slackware::Slackget::SpecialFiles::PACKAGES class, and automatically call the clean_description() method.

=cut

sub extract_informations {
	my $self = shift;
	foreach (@_){
# 		print "Analysing package " ;
		if($_ =~ /PACKAGE NAME:\s+(.*)\.tgz\s*\n/)
		{
			$self->_setId($1);
# 			print "[DEBUG] Slackware::Slackget::Package -> rename package to $1\n";
			$self->fill_object_from_package_name();
			
		}
		if($_ =~ /(COMPRESSED PACKAGE SIZE|PACKAGE SIZE \(compressed\)):\s+(.*) K\n/)
		{
# 			print "size_c ";
			$self->setValue('compressed-size',$2);
		}
		if($_ =~ /(UNCOMPRESSED PACKAGE SIZE|PACKAGE SIZE \(uncompressed\)):\s+(.*) K\n/)
		{
# 			print "size_u ";
			$self->setValue('uncompressed-size',$2);
		}
		if($_ =~ /PACKAGE LOCATION:\s+(.*)\s*\n/)
		{
# 			print "location ";
			$self->setValue('package-location',$1);
		}
		if($_ =~ /PACKAGE REQUIRED:\s+(.*)\s*\n*/)
		{
			$self->setValue('required',$1) if($1 !~ /^PACKAGE/);;
		}
		if($_ =~ /PACKAGE SUGGESTS:\s+([^\n]*)\s*\n*/)
		{
			$self->setValue('suggest',$1) if($1 !~ /^PACKAGE/);
		}
		if($_=~/PACKAGE DESCRIPTION:\s*\n(.*)/ms)
		{
# 			print "descr ";
			$self->setValue('description',$1);
			$self->{PACK}->{description}=~ s/\n/\n\t\t/g;
			$self->clean_description ;
			my @t = split(/\s/,$self->getValue('description'));
			$self->{STATS}->{dwc} = scalar(@t);
# 			print "[DEBUG] Slackware::Slackget::Package -> package ",$self->get_id()," ($self) have $self->{STATS}->{dwc} words in its description.\n";
# 			print Dumper($self);<STDIN>;
		}
	}
}

=head2 clean_description

remove the "<package_name>: " string in front of each line of the description. Remove extra tabulation (for identation).

	$package->clean_description();

=cut

sub clean_description{
	my $self = shift;
	if($self->{PACK}->{name} && defined($self->{PACK}->{description}) && $self->{PACK}->{description})
	{
		$self->{PACK}->{description}=~ s/\s*\Q$self->{PACK}->{name}\E\s*:\s*/ /ig;
# 		my @descr  = split(/\s*\Q$self->{PACK}->{name}\E\s*:/,$self->{PACK}->{description});
# 		$self->{PACK}->{description} = join(' ',@descr);
		$self->{PACK}->{description}=~ s/\t{4,}/\t\t\t/g;
		$self->{PACK}->{description}=~ s/\n\s+\n/\n/g;
	}
	$self->{PACK}->{description}.="\n\t\t";
	return 1;
}

=head2 grab_info_from_description

Try to find some informations in the description. For example, packages from linuxpackages.net contain a line starting by Packager: ..., this method will extract this information and re-set the package-maintener tag.

The supported tags are: package-maintener, info-destination-slackware, info-packager-mail, info-homepage, info-packager-tool, info-packager-tool-version

	$package->grab_info_from_description();

=cut

sub grab_info_from_description
{
	my $self = shift;
	# NOTE: je remplace ici tout les elsif() par des if() histoire de voir si l'extraction d'information est plus interressante.
	if($self->{PACK}->{description}=~ /this\s+version\s+.*\s+was\s+comp(iled|lied)\s+for\s+([^\n]*)\s+(.|\n)*\s+by\s+([^\n\t]*)/i){
		$self->setValue('info-destination-slackware',$2);
		$self->setValue('package-maintener',$4);
	}
	if($self->{PACK}->{description}=~ /\s*(http:\/\/[^\s]+)/i){
		$self->setValue('info-homepage',$1);
	}
	if($self->{PACK}->{description}=~ /\s*([\w\.\-]+\@[^\s]+\.[\w]+)/i){
		$self->setValue('info-packager-mail',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package\s+created\s+by:\s+(.*)\s+&lt;([^\n\t]*)&gt;/i){
		$self->setValue('info-packager-mail',$2);
		$self->setValue('package-maintener',$1);
	}
	elsif($self->{PACK}->{description}=~ /Packager:\s+(.*)\s+&lt;(.*)&gt;/i){
		$self->setValue('package-maintener',$1);
		$self->setValue('info-packager-mail',$2);
	}
	elsif($self->{PACK}->{description}=~ /Package\s+created\s+.*by\s+(.*)\s+\(([^\n\t]*)\)/i){
		$self->setValue('package-maintener',$1);
		$self->setValue('info-packager-mail',$2);
	}
	elsif ( $self->{PACK}->{description}=~ /Packaged by ([^\s]+) ([^\s]+) \((.*)\)/i)
	{
		$self->setValue('package-maintener',"$1 $2");
		$self->setValue('info-packager-mail',$3);
	}
	elsif($self->{PACK}->{description}=~ /\s*Package\s+Maintainer:\s+(.*)\s+\(([^\n\t]*)\)/i){
		$self->setValue('package-maintener',$1);
		$self->setValue('info-packager-mail',$2);
	}
	elsif($self->{PACK}->{description}=~ /Packaged\s+by\s+(.*)\s+&lt;([^\n\t]*)&gt;/i){
		$self->setValue('package-maintener',$1);
		$self->setValue('info-packager-mail',$2);
	}
	
	if ( $self->{PACK}->{description}=~ /Package created by ([^\s]+) ([^\s]+)/i)
	{
		$self->setValue('package-maintener',"$1 $2");
	}
	
	if($self->{PACK}->{description}=~ /Packaged\s+by:?\s+(.*)(\s+(by|for|to|on))?/i){
		$self->setValue('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Package\s+created\s+by:?\s+([^\n\t]*)/i){
		$self->setValue('package-maintener',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package\s+created\s+by\s+(.*)\s+\[([^\n\t]*)\]/i){
		$self->setValue('info-homepage',$2);
		$self->setValue('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Packager:\s+([^\n\t]*)/i){
		$self->setValue('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Packager\s+([^\n\t]*)/i){
		$self->setValue('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Home\s{0,1}page: ([^\n\t]*)/i){
		$self->setValue('info-homepage',$1);
	}
	if($self->{PACK}->{description}=~ /Package URL: ([^\n\t]*)/i){
		$self->setValue('info-homepage',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package creat(ed|e) with ([^\s]*) ([^\s]*)/i){
		$self->setValue('info-packager-tool',$2);
		$self->setValue('info-packager-tool-version',$3);
	}
	
}

=head2 to_XML

return the package as an XML encoded string.

	$xml = $package->to_XML();

=cut

sub to_XML
{
	my $self = shift;
	
	my $xml = "\t<package id=\"$self->{ROOT}\">\n";
	if(defined($self->{STATUS}) && ref($self->{STATUS}) eq 'Slackware::Slackget::Status')
	{
		$xml .= "\t\t".$self->{STATUS}->to_XML()."\n";
	}
	if($self->{PACK}->{'package-date'}){
		$xml .= "\t\t".$self->{PACK}->{'package-date'}->to_XML();
		$self->{TMP}->{'package-date'}=$self->{PACK}->{'package-date'};
		delete($self->{PACK}->{'package-date'});
	}
	if($self->{PACK}->{'date'}){
		$xml .= "\t\t".$self->{PACK}->{'date'}->to_XML();
		$self->{TMP}->{'date'}=$self->{PACK}->{'date'};
		delete($self->{PACK}->{'date'});
	}
	if($self->{STATS}){
		if($self->{STATS}->{dwc} == 0 && scalar(@{$self->{STATS}->{hw}}) > 0 && defined($self->getValue('description')) ){
			my @t = split(/\s/,$self->getValue('description'));
			$self->{STATS}->{dwc} = scalar(@t);
		}
# 		print "[Slackware::Slackget::Package->to_XML] $self->{ROOT} ($self) : <statistics dwc=\"".$self->{STATS}->{dwc}."\" hw=\":".join(':',@{$self->{STATS}->{hw}}).":\" />\n";
# 		print Dumper($self);<STDIN>;
		
		$xml .= "\t\t<statistics dwc=\"".$self->{STATS}->{dwc}."\" hw=\":".join(':',@{$self->{STATS}->{hw}}).":\" />\n";
	}
	foreach (keys(%{$self->{PACK}})){
		next if(/^_[A-Z_]+$/);
		$xml .= "\t\t<$_><![CDATA[$self->{PACK}->{$_}]]></$_>\n" if(defined($self->{PACK}->{$_}));
	}
	$self->{PACK}->{'package-date'}=$self->{TMP}->{'package-date'};
	delete($self->{TMP});
	$xml .= "\t</package>\n";
	return $xml;
}

=head2 to_string

Alias for to_XML()

=cut

sub to_string{
	my $self = shift;
	$self->toXML();
}

=head2 to_HTML

return the package as an HTML string

	my $html = $package->to_HTML ;

Note: I have design this method for 2 reasons. First for an easy integration of the search result in a GUI, second for my website search engine. So this HTML may not satisfy you. In this case just generate new HTML from accessors ;-)

=cut

sub to_HTML
{
	my $self = shift;
	my $html = "\t<h3>$self->{ROOT}</h3>\n<p>";
	if(defined($self->{STATUS}) && ref($self->{STATUS}) eq 'Slackware::Slackget::Status')
	{
		$html .= "\t\t".$self->{STATUS}->to_HTML()."\n";
	}
	if($self->{PACK}->{'package-date'}){
		$html .= "\t\t".$self->{PACK}->{'package-date'}->to_HTML();
		$self->{TMP}->{'package-date'}=$self->{PACK}->{'package-date'};
		delete($self->{PACK}->{'package-date'});
	}
	if($self->{PACK}->{'date'}){
		$html .= "\t\t".$self->{PACK}->{'date'}->to_HTML();
		$self->{TMP}->{'date'}=$self->{PACK}->{'date'};
		delete($self->{PACK}->{'date'});
	}
	foreach (keys(%{$self->{PACK}})){
		if($_ eq 'package-source')
		{
			$html .= "<strong>$_ :</strong> <b style=\"color:white;background-color:#6495ed\">$self->{PACK}->{$_}</b><br/>\n" if(defined($self->{PACK}->{$_}));
		}
		else
		{
			$html .= "<strong>$_ :</strong> $self->{PACK}->{$_}<br/>\n" if(defined($self->{PACK}->{$_}));
		}
	}
	$self->{PACK}->{'package-date'}=$self->{TMP}->{'package-date'};
	delete($self->{TMP});
	$html .="\n</p>";
	return $html;
}

=head1 PRINTING METHODS

=head2 print_restricted_info

Print a part of package information.

	$package->print_restricted_info();

=cut

sub print_restricted_info {
	my $self = shift;
	print "Information on package ".$self->get_id." :\n".
	"\tshort name : ".$self->name()." \n".
	"\tArchitecture : ".$self->architecture()." \n".
	"\tDownload size : ".$self->compressed_size()." KB \n".
	"\tSource : ".$self->getValue('package-source')."\n".
	"\tPackage version : ".$self->version()." \n";
}

=head2 print_full_info

Print all informations found in the package.

	$package->print_full_info();

=cut

sub print_full_info {
	my $self = shift;
	print "Information on package ".$self->get_id." :\n";
	foreach (keys(%{$self->{PACK}})) {
		print "\t$_ : $self->{PACK}->{$_}\n";
	}
}

=head2 fprint_restricted_info

Same as print_restricted_info, but output in HTML

	$package->fprint_restricted_info();

=cut

sub fprint_restricted_info {
	my $self = shift;
	print "<u><li>Information on package ".$self->get_id." :</li></u><br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>short name : </strong> ".$self->name()." <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Architecture : </strong> ".$self->architecture()." <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Download size : </strong> ".$self->compressed_size()." KB <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Source : </strong> ".$self->getValue('package-source')."<br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Package version : </strong> ".$self->version()." <br/>\n";
}

=head2 fprint_full_info

Same as print_full_info, but output in HTML

	$package->fprint_full_info();

=cut

sub fprint_full_info {
	my $self = shift;
	print "<u><li>Information on package ".$self->get_id." :</li></u><br/>\n";
	foreach (keys(%{$self->{PACK}})){
		print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>$_ : </strong> $self->{PACK}->{$_}<br/>\n";
	}
}

=head1 ACCESSORS

=head2 setValue

Set the value of a named key to the value passed in argument.

	$package->setValue($key,$value);

=cut

sub setValue {
	my ($self,$key,$value) = @_ ;
# 	print "Setting $key=$value for $self\n";
	$self->{PACK}->{$key} = $value ;
}


=head2 getValue

Return the value of a key :

	$string = $package->getValue($key);

=cut

sub getValue {
	my ($self,$key) = @_ ;
	return $self->{PACK}->{$key};
}

=head2 status

Return the current status of the package object as a Slackware::Slackget::Status object. This object is set by other class, and in most case you don't have to set it by yourself.

	print "The current status for ",$package->name," is ",$package->status()->to_string,"\n";

You also can set the status, by passing a Slackware::Slackget::Status object, to this method.

	$package->status($status_object);

This method return 1 if all goes well and undef else.

=cut

sub status {
	my ($self,$status) = @_ ;
	if(defined($status))
	{
		return undef if(ref($status) ne 'Slackware::Slackget::Status');
		$self->{STATUS} = $status ;
	}
	else
	{
		return $self->{STATUS} ;
	}
	
	return 1;
}



=head2 _setId [PRIVATE]

set the package ID (normally the package complete name, like aaa_base-10.0.0-noarch-1). In normal use you don't need to use this method

	$package->_setId('aaa_base-10.0.0-noarch-1');

=cut

sub _setId{
	my ($self,$id)=@_;
	$self->{ROOT} = $id;
}

=head2 get_id

return the package id (full name, like aaa_base-10.0.0-noarch-1).

	$string = $package->get_id();

=cut

sub get_id {
	my $self= shift;
	return $self->{ROOT};
}

=head2 description

return the description of the package.

	$string = $package->description();

=cut

sub description{
	my $self = shift;
	return $self->{PACK}->{description};
}

=head2 filelist

return the list of files in the package. WARNING: by default this list is not included !

	$string = $package->filelist();

=cut

sub filelist{
	my $self = shift;
	return $self->{PACK}->{'file-list'};
}

=head2 name

return the name of the package. 
Ex: for the package aaa_base-10.0.0-noarch-1 name() will return aaa_base

	my $string = $package->name();

=cut

sub name{
	my $self = shift;
	return $self->{PACK}->{name};
}

=head2 compressed_size

return the compressed size of the package

	$number = $package->compressed_size();

=cut

sub compressed_size{
	my $self = shift;
	return $self->{PACK}->{'compressed-size'};
}

=head2 uncompressed_size

return the uncompressed size of the package

	$number = $package->uncompressed_size();

=cut

sub uncompressed_size{
	my $self = shift;
	return $self->{PACK}->{'uncompressed-size'};
}

=head2 location

return the location of the installed package.

	$string = $package->location();

=cut

sub location{
	my $self = shift;
	if(exists($self->{PACK}->{'package-location'}) && defined($self->{PACK}->{'package-location'}))
	{
		return $self->{PACK}->{'package-location'};
	}
	else
	{
		return $self->{PACK}->{location};
	}
	
}

=head2 conflicts

return the list of conflicting pakage.

	$string = $package->conflict();

=cut

sub conflicts{
	my $self = shift;
	return $self->{PACK}->{conflicts};
}

=head2 suggests

return the suggested package related to the current package.

	$string = $package->suggest();

=cut

sub suggests{
	my $self = shift;
	return $self->{PACK}->{suggests};
}

=head2 required

return the required packages for installing the current package

	$string = $package->required();

=cut

sub required{
	my $self = shift;
	return $self->{PACK}->{required};
}

=head2 architecture

return the architecture the package is compiled for.

	$string = $package->architecture();

=cut

sub architecture {
	my $self = shift;
	return $self->{PACK}->{architecture};
}

=head2 version

return the package version.

	$string = $package->version();

=cut

sub version {
	my $self = shift;
	return $self->{PACK}->{version};
}

=head2 get_fields_list

return a list of all fields of the package. This method is suitable for example in GUI for displaying informations on packages.

	foreach my $field ( $package->get_fields_list )
	{
		qt_textbrowser->append( "<b>$field</b> : ".$package->getValue( $field )."<br/>\n" ) ;
	}

=cut

sub get_fields_list
{
	my $self = shift ;
	return keys(%{$self->{PACK}}) ;
}

# 
# =head2
# 
# return the 
# 
# =cut
# 
# sub {
# 	my $self = shift;
# 	return $self->{PACK}->{};
# }

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

L<http://www.infinityperl.org>

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

1; # End of Slackware::Slackget::Package
