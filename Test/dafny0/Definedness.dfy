// ----------------- wellformed specifications ----------------------

class SoWellformed {
  var xyz: int;
  var next: SoWellformed;

  function F(x: int): int
  { 5 / x }  // error: possible division by zero

  function G(x: int): int
    requires 0 < x;
  { 5 / x }

  function H(x: int): int
    decreases 5/x;  // error: possible division by zero
  { 12 }

  function I(x: int): int
    requires 0 < x;
    decreases 5/x;
  { 12 }

  method M(a: SoWellformed, b: int) returns (c: bool, d: SoWellformed)
    requires a.xyz == 7;  // error: not always defined
    ensures c ==> d.xyz == -7;  // error: not always defined
    decreases 5 / b;  // error: not always defined
  {
    c := false;
  }

  method N(a: SoWellformed, b: int) returns (c: bool, d: SoWellformed)
    decreases 5 / b;
    requires a.next != null;  // error: not always defined
    requires a.next.xyz == 7;  // this is well-defined, given that the previous line is
    requires b < -2;
    ensures 0 <= b ==> d.xyz == -7 && !c;
  {
    c := true;
  }

  method O(a: SoWellformed, b: int) returns (c: bool, d: SoWellformed)
    modifies a.next;  // this may not be well-defined, but that's okay for modifies clauses
  {
    c := true;
  }

  method P(a: SoWellformed, b: int) returns (c: bool, d: SoWellformed);
    requires next != null;
    modifies this;
    ensures next.xyz < 100;  // error: may not be well-defined (if body sets next to null)

  method Q(a: SoWellformed, s: set<SoWellformed>) returns (c: bool, d: SoWellformed);
    requires next != null;
    modifies s;
    ensures next.xyz < 100;  // error: may not be well-defined (if this in s and body sets next to null)

  method R(a: SoWellformed, s: set<SoWellformed>) returns (c: bool, d: SoWellformed);
    requires next != null && this !in s;
    modifies s;
    ensures next.xyz < 100;  // fine
}

// ---------------------- welldefinedness checks for statements -------------------

class StatementTwoShoes {
  var x: int;

  function method F(b: int): StatementTwoShoes
    requires 0 <= b;
  {
    this
  }

  method M(p: StatementTwoShoes, a: int)
    modifies this, p;
  {
    p.x := a;  // error: receiver may be null
    F(a).x := a;  // error: LHS may not be well defined
    x := F(a-10).x;  // error: RHS may not be well defined
  }

  method N(a: int, b: int)
  {
    assert 5 / a == 5 / a;  // error: expression may not be well defined
    assume 20 / b == 5;  // error: expression may not be well defined
  }

  method O(a: int) returns (b: int)
  {
    if (20 / a == 5) {  // error: expression may not be well defined
      b := a;
    }
  }

  method P(a: int)
  {
    while (20 / a == 5) {  // error: expression may not be well defined
      break;
    }
  }

  method Q(a: int, b: int)
  {
    var i := 1;
    while (i < a)
      decreases F(i), F(a), a - i;  // error: component 1 may not be well defined
    {
      i := i + 1;
    }
    i := 1;
    while (i < a)
      decreases F(b), a - i;  // error: component 0 may not be well defined
    {
      i := i + 1;
    }
  }

  method R(a: int)
  {
    var i := 0;
    while (i < 100)  // The following produces 3 complaints instead of 1, because loop invariants are not subject to subsumption
      invariant F(a) != null;  // error: expression may not be well defined, and error: loop invariant may not hold
      decreases F(a), 100 - i;  // error: component 0 not well defined
    {
      i := i + 1;
    }
  }

  method S(a: int)
  {
    var j := 0;
    while (20 / a == 5 && j < 100)  // error: guard may not be well defined
      invariant j <= 100;
      decreases F(101 - j), 100 - j;
    {
      j := j + 1;
    }
  }

  method T(a: int)
    requires a != 0 && 20 / a == 5;
  {
    var k := a;
    var j := 0;
    while (20 / k == 5 && j < 100)  // fine
      decreases 100 - j;
    {
      j := j + 1;
    }
    j := 0;
    while (20 / k == 5 && j < 100)  // error: guard may not be well defined
      decreases 100 - j;
    {
      havoc k;
      j := j + 1;
    }
  }

  method U()
  {
    var i := 0;
    while (i < 100)
      invariant i <= 100;
      decreases 100 - i;
      invariant F(123 - i) == this;
    {
      i := i + 1;
    }
    i := 0;
    while (i < 100)
      decreases 100 - i;
      invariant F(if i==77 then -3 else i) == this;  // error: expression may not be well defined
    {
      i := i + 1;
      if (i == 77) { i := i + 1; }
    }
  }

  use function G(w: int): int { 5 }
  function method H(x: int): int;

  method V(s: set<StatementTwoShoes>, a: int, b: int)
    modifies s;
  {
    use G(12 / b);  // fine, because there are no welldefinedness checks on use statements
    foreach (m in s | m.x < 200)  // s may contain null, but the foreach excludes null
    {
      assume 0 <= m.x;
      assert m.x < 1000;
      use G(5 / m.x);  // fine, because there are no welldefinedness checks on use statements
      m.x := m.x + 1;
    }
    foreach (m in s + {F(a)})  // error: collection expression may not be well defined
    {
      m.x := 5;  // error: possible modifies clause violation
    }
    foreach (m in s | F(H(m.x)) == this)  // error: range expression may not be well defined
    {
      m.x := H(m.x);
    }
    foreach (m in s)
    {
      m.x := 100 / m.x;  // error: RhS may not be well defined
    }
  }

  method W(x: int)
  {
    var i := 0;
    while (i < 100)
      // The following line produces two complaints, thanks to the w-encoding of the loop's invariant definedness checking
      invariant 5 / x != 5 / x;  // error: not well-defined, and error: loop invariant does not hold initially
      decreases 100 - i;
    {
      i := i + 1;
    }
  }
}