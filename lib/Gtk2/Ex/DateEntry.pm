package Gtk2::Ex::DateEntry;
$Gtk2::Ex::TimeEntry::VERSION = 0.01;
use strict;
use warnings;
use Carp;


use Gtk2;
use DateTime;

use Glib qw(TRUE FALSE);
our $VERSION = 3;

use constant DEBUG => 0;

use Glib::Object::Subclass
    Gtk2::Entry::,
    interfaces  => [ 'Gtk2::CellEditable' ],
    signals => {
        value_changed => {
           class_closure => \&_do_value_changed,
           flags         => ['run-first']     ,
           return_type   => undef             ,
           param_types   => []                ,
        },
    }
;

sub INIT_INSTANCE {
    my $self = shift;
    $self->signal_connect('key-press-event' => \&_do_key_press_event);
    $self->signal_connect('focus-out-event' => \&_do_focus_out_event);
}

sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    
    my $pname = $pspec->get_name;
    
    # handle changes to the value parameter (emit a signal on change)
    if ($pname eq 'value') {
        $self->set_value($newval);
    }
    else {
        $self->{$pname} = $newval;
    }
}

sub get_value {
    my $self = shift;
    $self->{datetime} ? $self->{datetime}->ymd : undef;
}

sub set_value {
    carp 'usage $date_entry->set_value($new_value)' unless @_ == 2;
    my $self = shift;
    my $newval = shift;
    
    
    # parse the new value if defined
    if (defined $newval) {
        $newval = $self->_parse_input($newval);
    }
    my $oldval = $self->{datetime};
    
    if (! defined $oldval && ! defined $newval) {
        $self->_display_output;
    }
    elsif (! defined $oldval && defined $newval ||
           ! defined $newval && defined $oldval ||
           $oldval ne $newval) {
        $self->{datetime} = $newval;
        $self->signal_emit('value-changed');
    }
    else {
        $self->_display_output;
    }
    
}

sub set_today {
    my $self = shift;
    my ($hour, $minute) = (localtime time)[2,1];
    
    my $value = sprintf '%02d:%02d', $hour, $minute;
    
    $self->set_value( $value );
}

sub _do_value_changed {
    my $self = shift;
    my $value = $self->get_value;
    $self->_display_output;
}

sub _do_focus_out_event {
    my $self = shift;
    $self->set_value($self->get_text);
    return FALSE;
}

sub _do_key_press_event {
    my $self = shift;
    my $key  = shift;
    my $key_val = $key->keyval;
    
    # entry pressed, parse input
    if ($key_val == 65293) {
        $self->set_value($self->get_text);
        return FALSE;
    }
    # laft arrow key pressed
    elsif ($key_val >= 65361 && $key_val <= 65364) {
        $self->set_value($self->get_text);
        return $self->_do_key_left  if $key_val == 65361;
        return $self->_do_key_right if $key_val == 65363;
        return $self->_do_key_up    if $key_val == 65362;
        return $self->_do_key_down  if $key_val == 65364;
    }
    # pass everything else on
    else {
        return FALSE;
    }
}

sub _do_key_left {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('left') and return TRUE if ! $selected;

    
    for ($selected) {
        if    ($_ eq 'all'  ) { return FALSE }
        elsif ($_ eq 'month') { $self->set_selected_component('all')   }
        elsif ($_ eq 'day'  ) { $self->set_selected_component('month') }
        elsif ($_ eq 'year' ) { $self->set_selected_component('day')   }
    }
    
    print $self->get_selected_component, "\n";
    return TRUE;
}

sub _do_key_right {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('right') and return TRUE if !$selected;
    
    for ($selected) {
        if    ($_ eq 'all'  ) { return FALSE }
        elsif ($_ eq 'month') { print "A"; $self->set_selected_component('day')   }
        elsif ($_ eq 'day'  ) { print "B"; $self->set_selected_component('year')  }
        elsif ($_ eq 'year' ) { print "C"; $self->set_selected_component('all')   }
    }
    return TRUE;
}

sub _do_key_up {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('up') and return TRUE unless $selected;
    
    my $obj = $self->{datetime};
    for ($selected) {
        if    ($_ eq 'all'  ) { $obj->add(days  => 7) }
        elsif ($_ eq 'month') { $obj->add(months => 1) }
        elsif ($_ eq 'day'  ) { $obj->add(days  => 1) }
        elsif ($_ eq 'year' ) { $obj->add(years => 1)   }
    }      

    $self->_display_output;
    $self->set_selected_component($selected);
    
    return TRUE;
}

sub _do_key_down {
    my $self = shift;
    my $selected = $self->get_selected_component;  
    $self->_select_closest_component('down') and return TRUE unless $selected;
    
    print "DOWN\n";
    
    my $obj = $self->{datetime};
    for ($selected) {
        if    ($_ eq 'all'  ) { $obj->subtract(days  => 7) }
        elsif ($_ eq 'month') { $obj->subtract(months => 1) }
        elsif ($_ eq 'day'  ) { $obj->subtract(days  => 1) }
        elsif ($_ eq 'year' ) { $obj->subtract(years => 1) }
    }
    
    $self->_display_output;
    $self->set_selected_component($selected);
    return TRUE;
}

sub _display_output {
    my $self  = shift;
    
    my $obj = $self->{datetime};
    my $output = $obj ? sprintf ('%02d/%02d/%4d', $obj->month, $obj->day, $obj->year) : '';
    $self->set_text($output);
}


{
    my %pos = (
        month => [0,2],
        day   => [3,5],
        year  => [6,10],
        all   => [0,10]
    );


    sub get_selected_component {
        my $self = shift;
        
        
        my ($start, $end) = $self->get_selection_bounds;
        $start = 0 unless $start;
        $end = 0 unless $end;
        return undef if $start == $end;
        
        for my $name (keys %pos) {
            my $coords = $pos{$name};
            if ($start == $coords->[0] && $end == $coords->[1]) {
                return $name;
            }
        }
        
        # no componenet selected if we got here
        return undef;
    }
    
    
    sub set_selected_component {

        confess q[usage is $date_entry->set_selected_component($field)] unless @_ == 2;
        my $self  = shift;
        my $field = shift;
        
        if (! defined $field || $field eq 'none' || $field eq '') {
            $self->select_region(0,0);
        } else {
            # throw exception if not a valid component name
            confess q[$field must be one of undef, none, year, month, day]
                if ! exists $pos{$field};
            $self->select_region(@{$pos{$field}});
        }
    }
}  # end encapsulated %pos variable



sub _select_closest_component {
    my $self      = shift;
    my $direction = shift;
    my $cursor = $self->get_position;
    
    if ($cursor == 0 || $cursor == 1) {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 2 && $direction ne 'right') {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 2 && $direction eq 'right') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 3 && $direction eq 'left') {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 3 && $direction ne 'left') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 4) {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 5 && $direction ne 'right') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 5 && $direction eq 'right') {
        $self->set_selected_component('year');
    }
    elsif ($cursor == 6 && $direction eq 'left') {
        $self->set_selected_component('year');
    }
    elsif ($cursor == 6 && $direction ne 'left') {
        $self->set_selected_component('year');
    }
    elsif ($cursor == 7 && $direction eq 'left') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 7) {
        $self->set_selected_componenet('year');
    }
    elsif ($cursor >= 8) {
        $self->set_selected_component('year');
    }
    
    return TRUE;
}

sub _parse_input {
    my $self  = shift;
    my $value = shift || '';
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return undef if ! defined $value || $value eq '';
    
    
    
    my ($d, $m, $y);
    if ($value =~ /^(\d{1,2})$/) {
        $d = $1;
        $m = 0;
        $y = 0;
    }
    elsif ($value =~ /^([01]?[0-9])([.-\/\\])?([0-3][0-9])\2(([0-9]{2})|([0-9]{4}))?$/) {
        $m = $1;
        $d = $3;
        $y = $4 || 0;
    }
    else {
        return $self->{datetime};
    }

    DateTime->new(day => $d, month => $m, year => $y);
    
}


1;


__END__

=head1 NAME

Gtk2::Ex::TimeEntry -- Widget for entering times

=head1 SYNOPSIS

 use Gtk2::Ex::TimeEntry;
 $te = Gtk2::Ex::TimeEntry->new (value => '13:00:00');
 $te->set_value('1pm');
 $te->get_value;

=head1 WIDGET HIERARCHY

    Gtk2::Widget
      Gtk2::Entry
        Gtk2::Ex::TimeEntry

=head1 DESCRIPTION

C<Gtk2::Ex::TimeEntry> displays and edits a time in HH::MM PM format with some
convienence functions.

Use the up and down keys to modify the invidual components of the value, and the
left and right keys to navigate between them. Pressing up or down while the
entire contents of the entry is selected (such as when you focus-in) modifies
the value in 15 minute increments.

The time is stored in HH:MM:SS format (but display in HH:MM PM format). If you
entry a value 24:00:00 or higher, it will loop back around t

You can also type a time into the entry into various formats, which will be
parsed and then displayed in the entry in HH:MM PM format. Here are some
examples of things you can enter into the widget and the resulting internal and
display values.

=over 4

INPUT       VALUE       DISPLAY
1           01:00:00    01:00 AM
10          10:00:00    10:00 AM
420         04:20:00    04:20 AM
4:20        04:20:00    04:20 AM
420pm       16:20:00    04:20 PM
04:20 PM    16:20:00    04:20 PM
30:20:00    04:20:00    04:20 AM

=back 4

=head1 FUNCTIONS

=over 4

=item C<< $te = Gtk2::Ex::TimeEntry->new (key=>value,...) >>

Create and return a new DateSpinner widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.  Eg.

    my $te = Gtk2::Ex::TimeEntry->new (value => '16:00:00');

=item C<< $te->get_selected_component >>

Returns the currently selected component - any of hours, minutes, meridiem, all
or an emptry string. An emptry string will be returned if the selection bounds
contains more or less than 1 individual component, and will return all if all
componentes are selected.

=item C<< $te->set_selected_component($component) >>

Highlights the given component, which can then be edited by typing over it or
pressing the arrow keys up or down. You can pass the values all, hours, minutes,
meridiem, an emptry string, or undef.

=item C<< $te->set_now >>

Set the widget value to the current time. 

=back

=head1 PROPERTIES

=over 4

=item C<value> (string, default '')

The current time format in ISO format HH:MM:SS. Can be set to an empty string
for no time. When setting the value you, you may pass any acceptable value
outlined in the widget description, but the time will always be stored in
HH:MM:SS format.

=back

=head1 SIGNALS

=over 4

=item C<value-changed>)

Emitted after a succesful value change.

=back

=head1 SEE ALSO

L<Gtk2::Ex::TimeEntry::CellRenderer>

=head1 AUTHOR

Jeffrey Hallock <jeffrey dot hallock at gmail dot com>

=head1 BUGS

None known. Please send bugs to <jeffrey dot hallock at gmail dot org>.
Patches and suggestions welcome.

=head1 LICENSE

Gtk2-Ex-TimeEntry is Copyright 2009 Jeffrey Hallock

Gtk2-Ex-TimeEntry is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-TimeEntry is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-TimeEntry.  If not, see L<http://www.gnu.org/licenses/>.

=cut
