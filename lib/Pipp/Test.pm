# Copyright (C) 2004-2009, Parrot Foundation.

=head1 NAME

Pipp::Test - testing routines for Pipp

=head1 SYNOPSIS

Set the number of tests to be run like this:

    use Pipp::Test tests => 8;

Write individual tests like this:

    language_output_is(<<'CODE', <<'OUTPUT', "description of test");
    123
    CODE
    123
    OUTPUT

=head1 DESCRIPTION

This module provides various Pipp-specific test functions.

=head2 Functions

The parameter C<$language> is the language of the code.
The parameter C<$code> is the code that should be executed or transformed.
The parameter C<$expected> is the expected result.
The parameter C<$unexpected> is the unexpected result.
The parameter C<$description> should describe the test.

Any optional parameters can follow.  For example, to mark a test as a TODO test
(where you know the implementation does not yet work), pass:

    todo => 'reason to consider this TODO'

at the end of the argument list.  Valid reasons include C<bug>,
C<unimplemented>, and so on.

B<Note:> you I<must> use a C<$description> with TODO tests.

=over 4

=item C<language_output_is( $language, $code, $expected, $description)>

=item C<language_error_output_is( $language, $code, $expected, $description)>

Runs a language test and passes the test if a string comparison
of the output with the expected result it true.
For C<language_error_output_is()> the exit code also has to be non-zero.

=item C<language_output_like( $language, $code, $expected, $description)>

=item C<language_error_output_like( $language, $code, $expected, $description)>

Runs a language test and passes the test if the output matches the expected
result.
For C<language_error_output_like()> the exit code also has to be non-zero.

=item C<language_output_isnt( $language, $code, $expected, $description)>

=item C<language_error_output_isnt( $language, $code, $expected, $description)>

Runs a language test and passes the test if a string comparison
if a string comparison of the output with the unexpected result is false.
For C<language_error_output_isnt()> the exit code also has to be non-zero.

=item C<skip($why, $how_many)>

Use within a C<SKIP: { ... }> block to indicate why and how many tests to skip,
just like in Test::More.

=item C<run_command($command, %options)>

Run the given $command in a cross-platform manner.

%options include...

    STDOUT    name of file to redirect STDOUT to
    STDERR    name of file to redirect STDERR to
    CD        directory to run the command in

For example:

    # equivalent to "cd some_dir && make test"
    run_command("make test", CD => "some_dir");

=item C<slurp_file($file_name)>

Read the whole file $file_name and return the content as a string.

=item C<convert_line_endings($text)>

Convert Win32 style line endins with Unix style line endings.

=item C<per_test( $ext, $test_no )>

Construct a path for a temporary files.
Takes C<$0> into account.

=item C<write_code_to_file($code, $code_f)>

Writes C<$code> into the file C<$code_f>.

=cut

package Pipp::Test;

use strict;
use warnings;
use lib qw( lib );

use Cwd;
use File::Spec;

use Pipp::FindParrot;

require Exporter;
require Test::Builder;
require Test::More;

our @EXPORT = qw( plan run_command skip slurp_file);

use base qw( Exporter );

my $builder = Test::Builder->new();

# Generate subs where the name serves as an
# extra parameter.
_generate_languages_functions();

sub import {
    my ( $class, $plan, @args ) = @_;

    $builder->plan( $plan, @args );

    __PACKAGE__->export_to_level( 2, __PACKAGE__ );
}

# this kludge is an hopefully portable way of having
# redirections ( tested on Linux and Win2k )
# An alternative is using Test::Output
sub run_command {
    my ( $command, %options ) = @_;

    my ( $out, $err, $chdir ) = _handle_test_options( \%options );

    local *OLDOUT if $out;    ## no critic Variables::ProhibitConditionalDeclarations
    local *OLDERR if $err;    ## no critic Variables::ProhibitConditionalDeclarations

    # Save the old filehandles; we must not let them get closed.
    open OLDOUT, '>&STDOUT'   ## no critic InputOutput::ProhibitBarewordFileHandles
        or die "Can't save     stdout"
        if $out;
    open OLDERR, '>&STDERR'   ## no critic InputOutput::ProhibitBarewordFileHandles
        or die "Can't save     stderr"
        if $err;

    open STDOUT, '>', $out or die "Can't redirect stdout to $out" if $out;

    # See 'Obscure Open Tricks' in perlopentut
    open STDERR, ">$err"      ## no critic InputOutput::ProhibitTwoArgOpen
        or die "Can't redirect stderr to $err"
        if $err;

    # If $command isn't already an arrayref (because of a multi-command
    # test), make it so now so the code below can treat everybody the
    # same.
    $command = _handle_command( $command );

    my $orig_dir;
    if ($chdir) {
        $orig_dir = cwd;
        chdir $chdir;
    }

    # Execute all commands
    # removed exec warnings to prevent this warning from messing up test results
    {
        no warnings 'exec';
        system($_) for ( @{$command} );
    }

    if ($chdir) {
        chdir $orig_dir;
    }

    my $exit_message = _prepare_exit_message();

    close STDOUT or die "Can't close    stdout" if $out;
    close STDERR or die "Can't close    stderr" if $err;

    open STDOUT, ">&", \*OLDOUT or die "Can't restore  stdout" if $out;
    open STDERR, ">&", \*OLDERR or die "Can't restore  stderr" if $err;

    return $exit_message;
}

sub per_test {
    my ( $ext, $test_no ) = @_;

    return unless defined $ext and defined $test_no;

    my $t = $0;    # $0 is name of the test script
    $t =~ s/\.t$/_$test_no$ext/;

    return $t;
}

sub write_code_to_file {
    my ( $code, $code_f ) = @_;

    open my $CODE, '>', $code_f or die "Unable to open '$code_f'";
    binmode $CODE;
    print $CODE $code;
    close $CODE;

    return;
}

# We can inherit from other modules, so we do so.
*plan = \&Test::More::plan;
*skip = \&Test::More::skip;

=item C<slurp_file($filename)>

Slurps up the filename and returns the content as one string.  While
doing so, it converts all DOS-style line endings to newlines.

=cut

sub slurp_file {
    my ($file_name) = @_;

    open( my $SLURP, '<', $file_name ) or die "open '$file_name': $!";
    local $/ = undef;
    my $file = <$SLURP> . '';
    $file =~ s/\cM\cJ/\n/g;
    close $SLURP or die $!;

    return $file;
}

sub convert_line_endings {
    my ($text) = @_;

    $text =~ s/\cM\cJ/\n/g;

    return;
}

sub _generate_languages_functions {

    my $package        = 'Pipp::Test';
    my %test_map = (
        language_output_is         => 'is_eq',
        language_error_output_is   => 'is_eq',
        language_output_like       => 'like',
        language_error_output_like => 'like',
        language_output_isnt       => 'isnt_eq',
        language_error_output_isnt => 'isnt_eq',
    );

    foreach my $func ( keys %test_map ) {
        push @EXPORT, $func;
        no strict 'refs';

        my $test_sub = sub {
            local *__ANON__ = $func;
            my $self        = shift;
            my ( $code, $expected, $desc, %options ) = @_;

            # set a todo-item for Test::Builder to find
            my $call_pkg = $builder->exported_to() || '';

            no strict 'refs';

            local *{ $call_pkg . '::TODO' } = ## no critic Variables::ProhibitConditionalDeclarations
                \$options{todo}
                if defined $options{todo};

            my $count = $builder->current_test() + 1;

            # These are the thing that depend on the actual language implementation
            my $out_f     = per_test( '_pct.out', $count );
            my $lang_f    = per_test( '.php', $count);
            my @test_prog = "./pipp $lang_f";

            Pipp::Test::write_code_to_file( $code, $lang_f );

            # set a todo-item for Test::Builder to find
            {
                # STDERR is written into same output file
                my $exit_code = Pipp::Test::run_command(
                    \@test_prog,
                    STDOUT => $out_f,
                    STDERR => $out_f
                );
                my $real_output = Pipp::Test::slurp_file($out_f);

                if ( $func =~ m/^ error_/xms ) {
                    return _handle_error_output( $builder, $real_output, $expected, $desc )
                        unless $exit_code;
                }
                elsif ($exit_code) {
                    $builder->ok( 0, $desc );

                    my $test_prog = join ' && ', @test_prog;
                    $builder->diag("'$test_prog' failed with exit code $exit_code.");

                    return 0;
                }

                my $meth = $test_map{$func};
                $builder->$meth( $real_output, $expected, $desc );
            }

            # The generated files are left in the t/* directories.
            # Let 'make clean' and 'svn:ignore' take care of them.

            return;
        };

        no strict 'refs';

        *{ $package . '::' . $func } = $test_sub;
    }
}

# The following methods are private.  They should not be used by modules
# inheriting from Pipp::Test.

sub _handle_error_output {
    my ( $builder, $real_output, $expected, $desc ) = @_;

    my $level = $builder->level();
    $builder->level( $level + 1 );
    $builder->ok( 0, $desc );
    $builder->diag(
        "Expected error but exited cleanly\n" . "Received:\n$real_output\nExpected:\n$expected\n" );
    $builder->level($level);

    return 0;
}

sub _handle_test_options {
    my $options = shift;
    # To run the command in a different directory.
    my $chdir = delete $options->{CD} || '';

    while ( my ( $key, $value ) = each %{ $options } ) {
        $key =~ m/^STD(OUT|ERR)$/
            or die "I don't know how to redirect '$key' yet!";
        my $strvalue = "$value";        # filehandle `eq' string will fail
        $value = File::Spec->devnull()  # on older perls, so stringify it
            if $strvalue eq '/dev/null';
    }

    my $out = $options->{'STDOUT'} || '';
    my $err = $options->{'STDERR'} || '';
    ##  File::Temp overloads 'eq' here, so we need the quotes. RT #58840
    if ( $out and $err and "$out" eq "$err" ) {
        $err = '&STDOUT';
    }
    return ( $out, $err, $chdir );
}

sub _handle_command {
    my $command = shift;
    $command = [$command] unless ( ref $command );

    if ( defined $ENV{VALGRIND} ) {
        $_ = "$ENV{VALGRIND} $_" for (@$command);
    }
    return $command;
}

sub _prepare_exit_message {
    my $exit_code = $?;
    return (
          ( $exit_code < 0 )    ? $exit_code
        : ( $exit_code & 0xFF ) ? "[SIGNAL $exit_code]"
        : ( $? >> 8 )
    );
}

sub read_parrot_config {
     my @parrot_config_exe = (
         $Pipp::FindParrot::parrot_config,
         'parrot/parrot_config', 
         '../../parrot_config',
         'parrot_config'
     );

    my %config;
    foreach my $exe (@parrot_config_exe) {
        no warnings;
        if (open my $PARROT_CONFIG, '-|', "$exe --dump") {
            print "Reading configuration information from $exe\n";
            while (<$PARROT_CONFIG>) {
                if (/(\w+) => '(.*)'/) { $config{$1} = $2 }
            }
            close $PARROT_CONFIG;
            last if %config;
        }
    }

    return %config;
}

1;

=head1 SEE ALSO

=over 4

=item L<Test/More>

=item L<Test/Builder>

=back

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
