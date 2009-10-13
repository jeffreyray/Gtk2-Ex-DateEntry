use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Gtk2::Ex::DateEntry',
    VERSION_FROM      => 'lib/Gtk2/Ex/DateEntry.pm', # finds $VERSION
    PREREQ_PM         => {  Gtk2     => 0,
                            DateTime => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/Ex/DateEntry.pm', # retrieve abstract from module
       AUTHOR         => 'Jeffrey Ray Hallock < jeffrey.ray at ragingpony dot com >') : ()),
);
