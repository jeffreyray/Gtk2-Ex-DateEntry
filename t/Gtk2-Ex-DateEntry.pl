#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More 'no_plan';

use FindBin qw($Bin);
use lib "$Bin/../lib";


use Gtk2 '-init';
use_ok( 'Gtk2::Ex::DateEntry' );

my $window = Gtk2::Window->new;
my $vbox   = Gtk2::VBox->new;
my $entry  = Gtk2::Ex::DateEntry->new;
my $entry2 = Gtk2::Ex::DateEntry->new;
$window->add($vbox);
$vbox->add($entry);
$vbox->add($entry2);
$window->show_all;
$window->signal_connect('destroy-event' => sub {Gtk2->main_quit });

Gtk2->main;