package Regexp::LogicPuzzle::StarBattle;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2019112901';

use Hash::Util::FieldHash qw [fieldhash];
use List::Util            qw [min max];

fieldhash my %subject;
fieldhash my %pattern;
fieldhash my %boxes;
fieldhash my %X;
fieldhash my %Y;
fieldhash my %nr_of_stars;

sub new  ($class) {bless \do {my $var} => $class}

sub init ($self) {
    $nr_of_stars {$self} = 1;
    $subject     {$self} = "";
    $pattern     {$self} = "";
    $self;
}

#
# Configure the puzzle
#
sub set_sizes ($self, $X, $Y = $X) {
    $X {$self} = $X;
    $Y {$self} = $Y;
    $self;
}

sub set_houses ($self, $houses) {
    my @lines    = split /\n/ => $houses;
    $X {$self} //= @lines;
    die "Mismatch in the number of lines" unless $X {$self} == @lines;

    foreach my $x (keys @lines) {
        my @chars = split // => $lines [$x];
        $Y {$self} //= @chars;
        die "Mismatch in the number of chars" unless $Y {$self} == @chars;
        
        foreach my $y (keys @chars) {
            my $house = $chars [$y];
            push @{$boxes {$self} {$house}} => [$x, $y];
        }
    }

    $self;
}


sub set_nr_of_stars ($self, $stars) {
    $nr_of_stars {$self} = $stars;
    $self;
}

#
# Given coordinates, give a name to the corresponding capture
#
my sub cell ($x, $y) {
    "cell_${x}_${y}";
}
my sub gref ($x, $y) {
    "\\g{" . cell ($x, $y) . "}";
}


sub __add_to_subject ($self, $text) {
    $subject {$self} .= $text;
}

sub __add_to_pattern ($self, $text) {
    $pattern {$self} .= $text;
}


sub __add_constraint ($self, $sub_subject, $sub_pattern, %args) {
    my $open  = $args {open}  // "<";
    my $close = $args {close} // ">";
    $self -> __add_to_subject ("$open$sub_subject$close");
    $self -> __add_to_pattern ("$open$sub_pattern$close");

    $self;
}


#
# Constraint for the minimum and maximum number of stars in a row,
# up to the given point. The maximum number of stars in a row (or column)
# up to a point with index k is 1 + int (k / 2), or $nr_of_stars, taking
# the minimum value of the two. The minimum number of stars in a row
# (or column) up to a point with index k is $nr_of_starts - int ((K - k) / 2),
# or 0, which ever is the maximum value of the two. Here K is the length
# of the row or column.
#
sub __add_line_constraints ($self, $x, $y) {
    my $X            = $self -> X;
    my $Y            = $self -> Y;
    my $nr_of_stars  = $nr_of_stars {$self};

    my $min_y_stars  = max (0, $nr_of_stars - int (($Y - $y) / 2));
    my $max_y_stars  = min (1 + int ($y / 2), $nr_of_stars);
    my $diff_y_stars = $max_y_stars - $min_y_stars;

    my $min_x_stars  = max (0, $nr_of_stars - int (($X - $x) / 2));
    my $max_x_stars  = min (1 + int ($x / 2), $nr_of_stars);
    my $diff_x_stars = $max_x_stars - $min_x_stars;

    $self -> __add_constraint (
        "*" x $max_y_stars,
        join ("" => map {gref ($x, $_)} 0 .. $y) . "\\*{0,$diff_y_stars}",
    );

    $self -> __add_constraint (
        "*" x $max_x_stars,
        join ("" => map {gref ($_, $y)} 0 .. $x) . "\\*{0,$diff_x_stars}",
    );

    $self;
}


sub build ($self) {
    my $subject          = "";
    my $pattern          = "";
    my $nr_of_stars      = $nr_of_stars {$self};
    my $full_stars       = "*"  x $nr_of_stars;
    my $up_to_full_stars = "\\*{0,$nr_of_stars}";

    my $X = $self -> X;
    my $Y = $self -> Y;

    for (my $x = 0; $x < $X; $x ++) {
        for (my $y = 0; $y < $Y; $y ++) {
            #
            # Star or not?
            #
            my $name  = cell $x, $y;
            $self -> __add_constraint ("*", "(?<$name>[*]?)[*]?",
                                       open  => ";",
                                       close => "");

            #
            # Add condition(s) that the 'current' cell is either
            # empty, or all its previous neighbours are empty.
            #
            if ($x > 0 || $y > 0) {
                my @neighbours;
                if ($x > 0) {
                    for my $z ($y - 1 .. $y + 1) {
                        next if $z < 0 || $z >= $Y {$self};
                        push @neighbours => [$x - 1, $z];
                    }
                }
                if ($y > 0) {
                    push @neighbours => [$x, $y - 1];
                }

                $self -> __add_constraint (
                         "",
                         "(?:" . gref ($x, $y) . "|" .
                                 join ("" => map {gref @$_} @neighbours) . ")"
                );
            }

            #
            # Constraints for the minimum/maximum number of stars 
            # to the left/above the current cell.
            #
            $self -> __add_line_constraints ($x, $y);
        }
    }

    $self;
}


sub subject ($self) {$subject {$self}}
sub pattern ($self) {$pattern {$self}}

sub X       ($self) {$X       {$self}}
sub Y       ($self) {$Y       {$self}}


1;

__END__

=head1 NAME

Regexp::LogicPuzzle::StarBattle - Abstract

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

=head1 TODO

=head1 SEE ALSO

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Regexp-LogicPuzzle.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2019 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
