=head1 NAME

t/php/oo.t - testing object oriented features

=head1 SYNOPSIS

    perl t/harness t/php/oo.t

=head1 DESCRIPTION

Defining and using objects.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../lib", "$FindBin::Bin/../../lib";

use Pipp::Test tests => 22;

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'definition of a class' );
<?php

class Dings {

    function bums() {
        echo "The function bums() in class Dings has been called.\n";
    }
}

echo "After class definition.\n"

?>
CODE
After class definition.
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'class constant in Foo' );
<?php

class Foo {

    const bar = "constant bar in class Foo\n";
}

echo Foo::bar;

?>
CODE
constant bar in class Foo
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'class constant in Bar' );
<?php

class Bar {

    const bar = "constant bar in class Bar\n";
}

echo Bar::bar;

?>
CODE
constant bar in class Bar
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'calling an instance method' );
<?php

class Dings {

    function bums() {
        echo "The function bums() in class Dings has been called.\n";
    }
}

$dings = new Dings;
$dings->bums();

?>
CODE
The function bums() in class Dings has been called.
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'class with a public member' );
<?php

class Dings {
    public $foo_member = 'a member of Foo';

    function bums() {
        echo "The function bums() in class Dings has been called.\n";
        return '';
    }
}

$dings = new Dings;
$dings->bums();

?>
CODE
The function bums() in class Dings has been called.
OUT


language_output_is( 'Pipp', <<'CODE', <<'OUT', 'calling a method within a method' );
<?php

class Foo {

    function bar() {
        echo "The method bar() of class Foo has been called.\n";
    }

    function baz() {
        echo "The method baz() of class Foo has been called.\n";
        $this->bar();
    }
}

$foo = new Foo;
$foo->baz();

?>
CODE
The method baz() of class Foo has been called.
The method bar() of class Foo has been called.
OUT

=for perl6

class Foo {

    has $.member is rw = 'a member of Foo';

    method echo_member() {
        print $.member;
        print "\n";
    }
}

my Foo $foo .= new();
$foo.echo_member();

=cut

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'accessing an attribute' );
<?php

class Foo {
    public $member = 'a member of Foo';

    function echo_member() {
        echo $this->member;
        echo "\n";
    }
}

$foo = new Foo;
$foo->echo_member();

?>
CODE
a member of Foo
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'attribute no called "member"', todo => 'only "member" is supported' );
<?php

class Foo {
    public $bar = "a member of Foo\n";

    function echo_member() {
        echo $this->bar;
    }
}

$foo = new Foo;
$foo->echo_member();

?>
CODE
a member of Foo
OUT


=for perl6

class Foo {
    method one_arg($arg_1) {
        print $arg_1;
        print "\n";
    }
}

my $foo = Foo.new();
$foo.one_arg('the first argument');

=cut

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'method with one parameter' );
<?php

class Foo {
    function one_arg($arg_1) {
        echo $arg_1;
        echo "\n";
    }
}

$foo = new Foo;
$foo->one_arg('the first argument');

?>
CODE
the first argument
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'method with one parameter' );
<?php

class Foo {
    function four_args($arg_1, $arg_2, $arg_3, $arg_4) {
        echo $arg_1;
        echo "\n";
        echo $arg_2;
        echo "\n";
        echo $arg_3;
        echo "\n";
        echo $arg_4;
        echo "\n";
    }
}

$foo = new Foo;
$foo->four_args( 'one', 'two', 'three', 'four' );

?>
CODE
one
two
three
four
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'class with constructor' );
<?php

class Foo {
    function __construct() {
        echo "method __construct() of class Foo was called.\n";
    }
}

$foo = new Foo;
echo 'Dummy statement, so that $foo is not returned.';
echo "\n";

?>
CODE
method __construct() of class Foo was called.
Dummy statement, so that $foo is not returned.
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'class with constructor, returning a PippObject' );
<?php

class Foo {
    function __construct() {
        echo "method __construct() of class Foo was called.\n";
    }
}

$foo = new Foo;

?>
CODE
method __construct() of class Foo was called.
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'constructor with one arg' );
<?php

class Foo {
    function __construct($msg) {
        echo "The message is $msg.\n";
    }
}

$foo = new Foo('what the message is');

?>
CODE
The message is what the message is.
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'ReflectionClass::getName()' );
<?php

class Foo {
}

$refl_1 = new ReflectionClass('Foo');
echo $refl_1->getName();
echo "\n";

?>
CODE
Foo
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'ReflectionExtension::getName()' );
<?php

$refl_1 = new ReflectionExtension('pipp_sample');
echo $refl_1->getName();
echo "\n";

?>
CODE
pipp_sample
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'static member' );
<?php

class A {
    public static $a = "static member \$a\n";

    function echo_static () {
        echo self::$a;
    }
}

$a = new A;
$a->echo_static();

?>
CODE
static member $a
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'static member after function' );
<?php

class A {
    function echo_static () {
        echo self::$a;
    }

    public static $a = "static member \$a\n";
}

$a = new A;
$a->echo_static();

?>
CODE
static member $a
OUT


language_output_is( 'Pipp', <<'CODE', <<'OUT', '__CLASS__' );
<?php

class A {
    function echo_class () {
        echo __CLASS__;
        echo "\n";
    }
}

$a = new A;
$a->echo_class();

?>
CODE
A
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', '__METHOD__' );
<?php

class A {
    function ecHO_class () {
        echo __CLASS__;
        echo "\n";
        echo __METHOD__;
        echo "\n";
    }

    function prinT_Class () {
        echo __CLASS__;
        echo "\n";
        echo __METHOD__;
        echo "\n";
    }
}

$a = new A;
$a->ecHO_class();
$a->prinT_Class();

?>
CODE
A
A::ecHO_class
A
A::prinT_Class
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'simple inheritance' );
<?php

class Hacker {
    public $member = 'a member of Hacker';

    function echo_member() {
        echo $this->member;
        echo "\n";
    }
}

class PHPHacker extends Hacker {
}

$hacker = new PHPHacker;
$hacker->echo_member();

?>
CODE
a member of Hacker
OUT


language_output_is( 'Pipp', <<'CODE', <<'OUT', 'attribute access', todo => 'not yet implemented' );
<?php

class Hacker {
    public $member_1 = "a member of Hacker\n";
}

$hacker = new Hacker;
echo $hacker->member_1;

?>
CODE
a member of Hacker
OUT

language_output_is( 'Pipp', <<'CODE', <<'OUT', 'inheritance, three generations', todo => 'not yet implemented' );
<?php

class Hacker {
    public $member_1 = "a member of Hacker\n";
}

class PerlHacker extends Hacker {
    public $member_2 = "a member of PerlHacker\n";
}

class MooseHacker extends PerlHacker {
    public $member_3 = "a member of MooseHacker\n";
}

$hacker = new MooseHacker;
echo $hacker->member_1;
echo $hacker->member_2;
echo $hacker->member_3;

?>
CODE
a member of Hacker
a member of PerlHacker
a member of MooseHacker
OUT


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
