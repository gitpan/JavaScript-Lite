#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use JavaScript::Lite;

{
  my $cx = JavaScript::Lite->new(1024 * 20);
  ok($cx, "got a context");
}

my $cx = JavaScript::Lite->new(1024 * 20);

lives_ok { $cx->eval_void("var hello = 'world';", "(eval)"); }
  "Valid JavaScript evaluates without error.";

throws_ok { $cx->eval_void("function foo() {", "(eval)"); }
  qr/missing \} after function body/,
  "Invalid javascript throws an exception";

throws_ok { $cx->eval_void("function foo() { return 'bar'; }", "script"); }
  qr/missing \} after function body/,
  "Valid javascript continues throwing up until we clear the error";

$cx->clear_error;

lives_ok { $cx->eval_void("function foo() { return 'bar'; }", "script"); }
  "Valid javascript works after clearing error";

my $xx = $cx->eval("foo();", "script");

is($xx, "bar", "Can get a value from javascript");

is($cx->invoke("foo"), "bar", "Can get a value from javascript function invocation");

$cx->assign("global_scalar", "foobar");

is($cx->eval("global_scalar", "(eval)"), "foobar", "retrieving a global scalar works");

my $good_hash = {
  foo => "fooze",
  bar => "barze",
  baz => 0.0051000
};

lives_ok { $cx->assign("good_hash", $good_hash); }
  "Assign a hash into a JS object.";

is($cx->eval("good_hash.foo", "(eval)"), "fooze", "can extract properties from hash");
is($cx->eval("good_hash.baz", "(eval)"), 0.0051, "can extract numerics from hash");
is($cx->eval("good_hash.baz", "(eval)"), "0.0051", "numerics are turned into numbers on entry");

$cx->assign_property("good_hash", "baz", "bingo");

is($cx->eval("good_hash.baz", "(eval)"), "bingo", "assign properties on objects");

my $bad_hash = {
  ohare => "chicago",
\ sfo => "callie",
  yy => [ "victoria", "vancouver" ]
};

lives_ok { $cx->assign("bad_hash", $bad_hash); }
  "Can assign nested structures (yet)."
;

is($cx->eval("bad_hash.yy[1]", "(eval)"), "vancouver", "Nested assignment works");

my $good_ary = [ $good_hash, $good_hash, $good_hash ];

lives_ok { $cx->assign("good_array", $good_ary); }
  "Assign array to javascript"
;

is($cx->eval("good_array[0].foo", "(eval)"), "fooze", "Hash copied successfully");
is($cx->eval("good_array[1].foo", "(eval)"), "fooze", "Hash copied successfully");

$cx->eval_void("good_array[1].foo = 5.95", "(eval)");

is($cx->eval("good_array[1].foo", "(eval)"), 5.95, "Assignment to hash works..");
is($cx->eval("good_array[0].foo", "(eval)"), "fooze", ".. and these are *copies*, not references.");

throws_ok { $cx->eval("in!valid!") }
  qr/\Qsyntax error at (eval)\E/,
  "Syntax error gets default filename (eval)"
;

$cx->clear_error;

throws_ok { $cx->eval("in!valid!", "foo.js") }
  qr/\Qsyntax error at foo.js\E/,
  "Filename can be overridden"
;

