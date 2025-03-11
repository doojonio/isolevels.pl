#!/usr/bin/env perl

use v5.38;

use DDP;
use DBI;

sub dbh {
    my $dbh = DBI->connect("dbi:Pg:database=postgres;host=db;port=5432", 'postgres', 'postgres');

    # $dbh->trace($dbh->parse_trace_flags('SQL|1|test'));

    $dbh;
}

sub create {

    my $dbh = dbh;
    $dbh->{AutoCommit} = 0;
    $dbh->{RaiseError} = 1;

    $dbh->prepare('drop table if exists isotest')->execute();
    $dbh->prepare('create table if not exists isotest (id text primary key, col1 integer)')->execute();

    $dbh->commit();
}


sub tr1 {
    say("tr1 $$");
    my $dbh = dbh;
    $dbh->begin_work;
    $dbh->prepare('set transaction isolation level SERIALIZABLE')->execute();

    p $dbh->selectall_arrayref("select * from isotest");

    sleep(5);

    p $dbh->selectall_arrayref("select * from isotest");

    $dbh->prepare("insert into isotest values ( 'asdas', (select sum(col1) + 100 from isotest limit 1))")->execute();

    p $dbh->selectall_arrayref("select * from isotest");

    $dbh->commit();
}

sub tr2 {
    say("tr2 $$");
    my $dbh = dbh;

    sleep(1);

    $dbh->begin_work;
    $dbh->prepare('set transaction isolation level SERIALIZABLE')->execute();

    $dbh->prepare("insert into isotest values (?, ?)")->execute(time, time);
    $dbh->prepare("insert into isotest values (?, ?)")->execute(time + 1, time + 1);
    $dbh->prepare("insert into isotest values (?, ?)")->execute(time + 2, time + 2);

    $dbh->commit();
}


create;

if (!fork) {
    tr1()
}
elsif (!fork) {
    tr2()
}
else {
    while (wait != -1) { }
    say 'done';
}
