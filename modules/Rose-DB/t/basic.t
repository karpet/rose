#!/usr/bin/perl -w

use strict;

use Test::More tests => 91;

BEGIN
{
  use_ok('Rose::DB');
  use_ok('Rose::DB::Registry');
  use_ok('Rose::DB::Registry::Entry');
  use_ok('Rose::DB::Constants');

  require 't/test-lib.pl';

  is(Rose::DB::Constants::IN_TRANSACTION(), -1, 'Rose::DB::Constants::IN_TRANSACTION');
  Rose::DB::Constants->import('IN_TRANSACTION');

  # Default
  Rose::DB->register_db(
    domain   => 'default',
    type     => 'default',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'default',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Aux
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'aux',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Generic
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'generic',
    driver   => 'NoneSuch',
    database => 'test',
    host     => 'localhost',
    username => 'someuser',
    password => '',
  );

  # Alias
  Rose::DB->alias_db(source => { domain => 'test',  type => 'aux'  },
                     alias  => { domain => 'atest', type => 'aaux' });

  package MyPgClass;
  @MyPgClass::ISA = qw(Rose::DB::Pg);
  sub format_date { die "boo!" }
}

is(IN_TRANSACTION, -1, 'IN_TRANSACTION');

my $db = Rose::DB->new;

is(Rose::DB->default_domain, 'test', 'default_domain() 1');
is(Rose::DB->default_type, 'default', 'default_type() 1');

ok(Rose::DB->db_exists('default'), 'db_exists() 1');
ok(!Rose::DB->db_exists('defaultx'), 'db_exists() 2');

ok(Rose::DB->db_exists(type => 'default'), 'db_exists() 3');
ok(!Rose::DB->db_exists(type => 'defaultx'), 'db_exists() 4');

ok(Rose::DB->db_exists(type => 'default', domain => 'test'), 'db_exists() 3');
ok(!Rose::DB->db_exists(type => 'defaultx', domain => 'testx'), 'db_exists() 4');

ok(!Rose::DB->db_exists(type => 'defaultx', domain => 'test'), 'db_exists() 3');

Rose::DB->error('foo');

is(Rose::DB->error, 'foo', 'error() 2');

$db->error('bar');

is(Rose::DB->error, 'bar', 'error() 3');
is($db->error, 'bar', 'error() 4');

eval { $db = Rose::DB->new };
ok(!$@, 'Valid type and domain');

Rose::DB->default_domain('foo');

is(Rose::DB->default_domain, 'foo', 'default_domain() 2');

eval { $db = Rose::DB->new };
ok($@, 'Invalid domain');

Rose::DB->default_domain('test');
Rose::DB->default_type('bar');

is(Rose::DB->default_type, 'bar', 'default_type() 2');

eval { $db = Rose::DB->new };
ok($@, 'Invalid type');

is(Rose::DB->driver_class('Pg'), 'Rose::DB::Pg', 'driver_class() 1');
is(Rose::DB->driver_class('xxx'), undef, 'driver_class() 2');

Rose::DB->driver_class(Pg => 'MyPgClass');
is(Rose::DB->driver_class('Pg'), 'MyPgClass', 'driver_class() 3');

$db = Rose::DB->new('aux');

is(ref $db, 'MyPgClass', 'new() single arg');

is($db->error('foo'), 'foo', 'subclass 1');
is($db->error, 'foo', 'subclass 2');

eval { $db->format_date('123') };
ok($@ =~ /^boo!/, 'driver_class() 4');

is(Rose::DB->default_connect_option('AutoCommit'), 1, "default_connect_option('AutoCommit')");
is(Rose::DB->default_connect_option('RaiseError'), 1, "default_connect_option('RaiseError')");
is(Rose::DB->default_connect_option('PrintError'), 1, "default_connect_option('PrintError')");
is(Rose::DB->default_connect_option('ChopBlanks'), 1, "default_connect_option('ChopBlanks')");
is(Rose::DB->default_connect_option('Warn'), 0, "default_connect_option('Warn')");

my $options = Rose::DB->default_connect_options;

is(ref $options, 'HASH', 'default_connect_options() 1');
is(join(',', sort keys %$options), 'AutoCommit,ChopBlanks,PrintError,RaiseError,Warn',
  'default_connect_options() 2');

Rose::DB->default_connect_options(a => 1, b => 2);

is(Rose::DB->default_connect_option('a'), 1, "default_connect_option('a')");
is(Rose::DB->default_connect_option('b'), 2, "default_connect_option('b')");

Rose::DB->default_connect_options({ c => 3, d => 4 });

is(Rose::DB->default_connect_option('c'), 3, "default_connect_option('c') 1");
is(Rose::DB->default_connect_option('d'), 4, "default_connect_option('d') 1");

my $keys = join(',', sort keys %{$db->default_connect_options});

$db->default_connect_options(zzz => 'bar');

my $keys2 = join(',', sort keys %{$db->default_connect_options});

is($keys2, "$keys,zzz", 'default_connect_options() 1');

$db->default_connect_options({ zzz => 'bar' });

$keys2 = join(',', sort keys %{$db->default_connect_options});

is($keys2, 'zzz', 'default_connect_options() 2');

$keys = join(',', sort keys %{$db->connect_options});

$db->connect_options(zzzz => 'bar');

$keys2 = join(',', sort keys %{$db->connect_options});

is($keys2, "$keys,zzzz", 'connect_option() 1');

$db->connect_options({ zzzz => 'bar' });

$keys2 = join(',', sort keys %{$db->connect_options});

is($keys2, 'zzzz', 'connect_option() 2');

$db->dsn('dbi:Pg:dbname=dbfoo;host=hfoo;port=pfoo');

#ok(!defined($db->database) || $db->database eq 'dbfoo', 'dsn() 1');
#ok(!defined($db->host) || $db->host eq 'hfoo', 'dsn() 2');
#ok(!defined($db->port) || $db->port eq 'port', 'dsn() 3');

eval { $db->dsn('dbi:mysql:dbname=dbfoo;host=hfoo;port=pfoo') };

ok($@ || $DBI::VERSION <  1.43, 'dsn() driver change');

$db = Rose::DB->new(domain  => 'test', type  => 'aux');
my $adb = Rose::DB->new(domain  => 'atest', type  => 'aaux');

is($db->class, 'Rose::DB', 'class() 1');

foreach my $attr (qw(domain type driver database username password 
                     connect_options post_connect_sql))
{
  is($db->username, $adb->username, "alias $attr()");
}

Rose::DB->modify_db(domain   => 'test', 
                    type     => 'aux', 
                    username => 'blargh',
                    connect_options => { Foo => 1 });

$db->init_db_info;
$adb->init_db_info;

is($db->username, $adb->username, "alias username() mod");
is($db->connect_options, $adb->connect_options, "alias connect_options() mod");

$db = Rose::DB->new('generic');

is(ref($db), 'Rose::DB::Generic', 'generic class');

is($db->dsn, 'dbi:NoneSuch:dbname=test;host=localhost', 'generic dsn');

#
# Registry tests
#

my $reg = Rose::DB->registry;

ok($reg->isa('Rose::DB::Registry'), 'registry');

my $entry = $reg->entry(domain => 'test', type => 'aux');

ok($entry->isa('Rose::DB::Registry::Entry'), 'registry entry 1');

foreach my $param (qw(autocommit database domain driver dsn host password port
                      print_error raise_error server_time_zone schema type 
                      username connect_options pre_disconnect_sql 
                      post_connect_sql))
{
  eval { $entry->$param() };

  ok(!$@, "entry $param()");
}

my $host     = $entry->host;
my $database = $entry->database;

Rose::DB->modify_db(domain => 'test', type => 'aux', host => 'foo', database => 'bar');

is($entry->host, 'foo', 'entry modify_db() 1');
is($entry->database, 'bar', 'entry modify_db() 2');

is($entry->connect_option('RaiseError') || 0, 0, 'entry connect_option() 1');
$entry->connect_option('RaiseError' => 1);
is($entry->connect_option('RaiseError'), 1, 'entry connect_option() 2');

$entry->pre_disconnect_sql(qw(sql1 sql2));
my $sql = $entry->pre_disconnect_sql;
ok(@$sql == 2 && $sql->[0] eq 'sql1' && $sql->[1] eq 'sql2', 'entry pre_disconnect_sql() 1');

$entry->post_connect_sql(qw(sql3 sql4));
$sql = $entry->post_connect_sql;
ok(@$sql == 2 && $sql->[0] eq 'sql3' && $sql->[1] eq 'sql4', 'entry post_connect_sql() 1');

$entry->raise_error(0);
is($entry->connect_option('RaiseError'), 0, 'entry raise_error() 1');

$entry->print_error(1);
is($entry->connect_option('PrintError'), 1, 'entry print_error() 1');

$entry->autocommit(1);
is($entry->connect_option('AutoCommit'), 1, 'entry autocommit() 1');

{
  package MyTest::DB;
  our @ISA = qw(Rose::DB);
  MyTest::DB->use_private_registry;
  MyTest::DB->default_type('dt');
  MyTest::DB->default_domain('dd');
  MyTest::DB->register_db(driver => 'sqlite');
}

$db = MyTest::DB->new;

is($db->type, 'dt', 'default type 1');
is($db->domain, 'dd', 'default domain 1');

{
  package MyTest::DB2;
  our @ISA = qw(Rose::DB);
  MyTest::DB2->default_type('xdt');
  MyTest::DB2->default_domain('xdd');

  MyTest::DB2->register_db(driver => 'sqlite');
}

$db = MyTest::DB2->new;

is($db->type, 'xdt', 'default type 2');
is($db->domain, 'xdd', 'default domain 2');