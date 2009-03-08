#! perl
# Copyright (C) 2009 The Perl Foundation

=head1 NAME

Configure.pl - a configure script for a high level language running on Parrot

=head1 SYNOPSIS

  perl Configure.pl --help

  perl Configure.pl

  perl Configure.pl --parrot_config=<path_to_parrot>

  perl Configure.pl --gen-parrot

=cut

use strict;
use warnings;
use 5.008;

my %valid_options = (
    'help'          => 'Display configuration help',
    'parrot-config' => 'Use configuration given by parrot_config binary',
    'gen-parrot'    => 'Automatically retrieve and build Parrot',
);


#  Get any options from the command line
my %options = get_command_options();


#  Print help if it's requested
if ($options{'help'}) {
    print_help();
    exit(0);
}


#  Update/generate parrot build if needed
if ($options{'gen-parrot'}) {
    system("$^X build/gen_parrot.pl");
}
    

#  Get a list of parrot-configs to invoke.
my @parrot_config_exe = (
    'parrot/parrot_config', 
    '../../parrot_config',
    'parrot_config'
);
if ($options{'parrot-config'} && $options{'parrot-config'} ne '1') {
    @parrot_config_exe = ($options{'parrot-config'});
}

#  Get configuration information from parrot_config
my %config = read_parrot_config(@parrot_config_exe);
unless (%config) {
    die <<"END";
Unable to locate parrot_config.
To automatically checkout (svn) and build a copy of parrot,
try re-running Configure.pl with the '--gen-parrot' option.
Or, use the '--parrot-config' option to explicitly specify
the location of parrot_config.
END
}

#  Create the Makefile using the information we just got
create_makefiles(
    \%config,
    { 'build/templates/Makefile.in'                => 'Makefile',
      'build/templates/src/pmc/Makefile.in'        => 'src/pmc/Makefile',
      'build/templates/lib/Pipp/FindParrot_pm.in'  => 'lib/Pipp/FindParrot.pm',
    }
);

#  Done.
done($config{'make'});


#  Process command line arguments into a hash.
sub get_command_options {
    my %options = ();
    for my $arg (@ARGV) {
        if ($arg =~ /^--(\w[-\w]*)(?:=(.*))?/ && $valid_options{$1}) {
            my ($key, $value) = ($1, $2);
            $value = 1 unless defined $value;
            $options{$key} = $value;
            next;
        }
        die qq/Invalid option "$arg".  See "perl Configure.pl --help" for valid options.\n/;
    }
    %options;
}


sub read_parrot_config {
    my @parrot_config_exe = @_;
    my %config = ();
    for my $exe (@parrot_config_exe) {
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


#  Generate a Makefile from a configuration
sub create_makefiles {
    my ($config, $makefiles) = @_;

    while (my ($template_fn, $target_fn) = each %{$makefiles}) {
        my $content;
        {
            open my $template_fh, '<', $template_fn or
                die "Unable to read $template_fn.";
            $content = join('', <$template_fh>);
            close $template_fn;
        }

        $config->{'win32_libparrot_copy'} = $^O eq 'MSWin32' ? 'copy $(BUILD_DIR)\libparrot.dll .' : '';
        $content =~ s/@(\w+)@/$config->{$1}/g;
        if ($^O eq 'MSWin32') {
            $content =~ s{/}{\\}g;
        }

        print "Creating $target_fn from $template_fn.\n";
        {
            open(my $target_fh, '>', $target_fn) 
                or die "Unable to write $target_fn\n";
            print $target_fh $content;
            close($target_fh);
        }
    }
}


sub done {
    my ($make) = @_;
    print <<"END";

You can now use '$make' to build Pipp.
After that, you can use '$make test' to run some local tests.
See 'docs/testing.pod' for how to run the PHP 5.3 testsuite.

END
    exit 0;
}


#  Print some help text.
sub print_help {
    print <<'END';
Configure.pl - Rakudo Configure

General Options:
    --help             Show this text
    --gen-parrot       Download and build a copy of Parrot to use
    --parrot-config=(config)
                       Use configuration information from config

END
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
