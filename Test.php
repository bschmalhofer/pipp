<?php

# a very simple testing package, or whatever it's called in PHP
$_test_ntests = 0;

function plan( $number_of_tests ) {
    echo "1..$number_of_tests\n";
}

function ok($cond, $desc) {
    proclaim($cond, $desc);
}

function nok($cond, $desc) {
    proclaim(!$cond, $desc);
}

function is($got, $expected, $desc) {
    proclaim($got == $expected, $desc);
}

function isnt($got, $expected, $desc) {
    proclaim($got != $expected, $desc);
}

function like($got, $expected, $desc) {
    proclaim( preg_match($expected, $got), $desc);
}

function unlike($got, $expected, $desc) {
    proclaim( ! preg_match($expected, $got), $desc);
}

function proclaim($cond, $desc) {
    global $_test_ntests;
    $_test_ntests++;
    if ( ! $cond ) {
       echo 'not ';
    }
    echo "ok $_test_ntests - $desc\n";  
}

?>
