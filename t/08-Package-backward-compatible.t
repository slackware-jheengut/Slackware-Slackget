use Test::More tests => 31;

BEGIN {
	use_ok( 'Slackware::Slackget::Package' );
}

my $package = new Slackware::Slackget::Package ('aaa_base-11.0.0-noarch-1','slackware');
ok($package);
my $package2 = new Slackware::Slackget::Package ('aaa_base-12.0.0-noarch-1','slackware');
ok($package2);

# version comparison tests

# numeric
ok( ($package <=> $package2) == -1 );
ok( $package == $package );
ok( $package < $package2 );
ok( $package <= $package2 );
ok( $package2 >  $package );
ok( $package2 >=  $package );

# string
ok( ($package cmp $package2) == -1 );
ok( $package eq $package );
ok( $package lt $package2 );
ok( $package le $package2 );
ok( $package2 gt  $package );
ok( $package2 ge  $package );

# Accessors test
ok($package->setValue('description','Package desciption test'));
ok($package->setValue('description','Package desciption test') eq 'Package desciption test' );
ok( $package->getValue('description') );
ok( $package->getValue('description') eq 'Package desciption test' );
ok( $package->get_id eq 'aaa_base-11.0.0-noarch-1');
ok( $package->description eq 'Package desciption test' );
ok( $package->name eq 'aaa_base');
ok( $package->version eq '11.0.0');
ok( $package->architecture eq 'noarch');
$package->merge($package2);
ok( $package->version eq '12.0.0');
ok( $package->description eq 'Package desciption test' );
ok( $package->is_heavy_word('aaa_base') );
ok($package->get_fields_list);

# Format test
ok($package->to_XML);
ok($package->to_HTML);
ok($package->to_string);
