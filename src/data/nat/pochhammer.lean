/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import tactic.abel

/-!
# The rising and falling factorial functions

We define and prove some basic relations about
`rising_factorial x n = x * (x+1) * ... * (x + n - 1)`
and its cousin `falling_factorial`.

## TODO
There is lots more in this direction:
* Pochhammer symbols.
* q-factorials, q-binomials.
* Defining Bernstein polynomials (e.g. as one way to prove Weierstrass' theorem).
-/

variables {R : Type*}

section
variables [semiring R]

/--
The rising factorial function: `rising_factorial x n = x * (x+1) * ... * (x + n - 1)`.

It is also sometimes called the Pochhammer polynomial, or the upper factorial.
Notations in the mathematics literature vary extensively.
-/
def rising_factorial : R → ℕ → R
| r 0 := 1
| r (n+1) := r * rising_factorial (r+1) n

@[simp]
lemma rising_factorial_zero {r : R} : rising_factorial r 0 = 1 := rfl
@[simp]
lemma rising_factorial_one {r : R} : rising_factorial r 1 = r := by simp [rising_factorial]

lemma rising_factorial_eq_mul_left {r : R} {n : ℕ} :
  rising_factorial r (n + 1) = r * rising_factorial (r+1) n := rfl

lemma rising_factorial_eq_mul_right {r : R} {n : ℕ} :
  rising_factorial r (n + 1) = rising_factorial r n * (r + n) :=
begin
  induction n with n ih generalizing r,
  { simp, },
  { rw [rising_factorial, ih, rising_factorial, nat.succ_eq_add_one],
    push_cast,
    rw [mul_assoc, add_comm (n : R) 1, add_assoc], }
end

lemma rising_factorial_mul_rising_factorial {r : R} {n m : ℕ} :
  rising_factorial r n * rising_factorial (r + n) m = rising_factorial r (n + m) :=
begin
  induction m with m ih,
  { simp, },
  { rw [rising_factorial_eq_mul_right, ←mul_assoc, ih, nat.add_succ, rising_factorial_eq_mul_right],
    push_cast,
    rw [add_assoc], }
end
end

section
variables [ring R]

/--
The falling factorial function: `falling_factorial x n = x * (x-1) * ... * (x - (n - 1))`.
-/
def falling_factorial : R → ℕ → R
| r 0 := 1
| r (n+1) := r * falling_factorial (r-1) n

@[simp]
lemma falling_factorial_zero {r : R} : falling_factorial r 0 = 1 := rfl
@[simp]
lemma falling_factorial_one {r : R} : falling_factorial r 1 = r := by simp [falling_factorial]

lemma falling_factorial_eq_mul_left {r : R} {n : ℕ} :
  falling_factorial r (n + 1) = r * falling_factorial (r-1) n := rfl

lemma falling_factorial_eq_mul_right {r : R} {n : ℕ} :
  falling_factorial r (n + 1) = falling_factorial r n * (r - n) :=
begin
  induction n with n ih generalizing r,
  { simp, },
  { rw [falling_factorial, ih, falling_factorial, nat.succ_eq_add_one],
    push_cast,
    rw [mul_assoc, add_comm (n : R) 1, ←sub_sub], }
end

lemma falling_factorial_mul_falling_factorial {r : R} {n m : ℕ} :
  falling_factorial r n * falling_factorial (r - n) m = falling_factorial r (n + m) :=
begin
  induction m with m ih,
  { simp, },
  { rw [falling_factorial_eq_mul_right, ←mul_assoc, ih, nat.add_succ,
      falling_factorial_eq_mul_right],
    push_cast,
    rw [sub_sub], }
end

end

section

def nat.falling_factorial : ℕ → ℕ → ℕ
| r 0 := 1
| r (n+1) := r * nat.falling_factorial (r-1) n

@[simp]
lemma nat.falling_factorial_zero {r : ℕ} : r.falling_factorial 0 = 1 := rfl

section
variables [ring R]

@[norm_cast]
lemma nat.falling_factorial_coe {r n : ℕ} :
  (nat.falling_factorial r n : R) = falling_factorial (r : R) n :=
begin
  induction n with n ih generalizing r,
  { simp, },
  { dsimp [nat.falling_factorial, falling_factorial],
    push_cast,
    rw [ih],
    { by_cases w : r = 0,
      { subst w, simp, },
      { replace w : 0 < r := nat.pos_of_ne_zero w,
        push_cast [w], }, }, },
end

@[simp]
lemma nat.falling_factorial_one {r : ℕ} : r.falling_factorial 1 = r :=
by simp [nat.falling_factorial]

lemma nat.falling_factorial_eq_mul_left {r n : ℕ} :
  r.falling_factorial (n + 1) = r * (r-1).falling_factorial n := rfl

lemma nat.falling_factorial_eq_mul_right {r n : ℕ} :
  r.falling_factorial (n + 1) = r.falling_factorial n * (r - n) :=
begin
  -- We could prove this from the ring case by using the injectivity of `ℕ → ℤ`,
  -- but it involves casing on `n ≤ r`, so it's easier to just redo it from scratch.
  induction n with n ih generalizing r,
  { simp, },
  { rw [nat.falling_factorial, ih, nat.falling_factorial, nat.succ_eq_add_one],
    rw [mul_assoc, add_comm n 1, ←nat.sub_sub], }
end

lemma nat.falling_factorial_mul_falling_factorial {r n m : ℕ} :
  r.falling_factorial n * (r - n).falling_factorial m = r.falling_factorial (n + m) :=
begin
  induction m with m ih,
  { simp, },
  { rw [nat.falling_factorial_eq_mul_right, ←mul_assoc, ih, nat.add_succ,
      nat.falling_factorial_eq_mul_right, nat.sub_sub], }
end

end

end

section
variables [comm_ring R]

lemma rising_factorial_eq_falling_factorial {r : R} {n : ℕ} :
  rising_factorial r n = falling_factorial (r + n - 1) n :=
begin
  induction n with n ih generalizing r,
  { refl, },
  { rw [rising_factorial, falling_factorial_eq_mul_right, ih, mul_comm, nat.succ_eq_add_one],
    push_cast,
    congr' 2; abel, }
end

end
section
lemma rising_factorial_eq_factorial {n : ℕ} :
  rising_factorial 1 n = n.factorial :=
begin
  induction n with n ih,
  { refl, },
  { rw [rising_factorial_eq_mul_right, nat.factorial, ih, mul_comm, add_comm], push_cast, }
end

lemma factorial_mul_rising_factorial {r n : ℕ} :
  r.factorial * rising_factorial (r+1) n = (r + n).factorial :=
begin
  rw [←rising_factorial_eq_factorial, add_comm, ←rising_factorial_eq_factorial],
  convert rising_factorial_mul_rising_factorial,
  simp,
end

lemma rising_factorial_eq_factorial_div_factorial {r n : ℕ} :
  rising_factorial (r+1) n = (r + n).factorial / r.factorial :=
(nat.div_eq_of_eq_mul_right (nat.factorial_pos _) factorial_mul_rising_factorial.symm).symm

lemma rising_factorial_eq_choose_mul_factorial {r n : ℕ} :
  rising_factorial (r+1) n = (r + n).choose n * n.factorial :=
begin
  rw rising_factorial_eq_factorial_div_factorial,
  -- TODO we need a `clear_denominators` tactic!
  apply nat.div_eq_of_eq_mul_right (nat.factorial_pos _),
  rw [mul_comm],
  convert (nat.choose_mul_factorial_mul_factorial (nat.le_add_left n r)).symm,
  simp,
end

lemma choose_eq_rising_factorial_div_factorial {r n : ℕ} :
  (r + n).choose n = rising_factorial (r+1) n / n.factorial :=
begin
  symmetry,
  apply nat.div_eq_of_eq_mul_right (nat.factorial_pos _),
  rw [mul_comm, rising_factorial_eq_choose_mul_factorial],
end
end

namespace ring_hom

local attribute [simp] rising_factorial falling_factorial

variables {S : Type*}

section
variables [semiring R] [semiring S]

@[simp]
lemma map_rising_factorial (f : R →+* S) {r : R} {n : ℕ} :
  f (rising_factorial r n) = rising_factorial (f r) n :=
begin
  induction n with n ih generalizing r,
  { simp, },
  { simp [ih], }
end

@[norm_cast]
lemma nat_coe_rising_factorial {r n : ℕ} :
  ((rising_factorial r n : ℕ) : R) = rising_factorial (r : R) n :=
by rw [←nat.coe_cast_ring_hom, map_rising_factorial]

end

section
variables [ring R] [ring S]

@[simp]
lemma map_falling_factorial (f : R →+* S) {r : R} {n : ℕ} :
  f (falling_factorial r n) = falling_factorial (f r) n :=
begin
  induction n with n ih generalizing r,
  { simp, },
  { simp [ih], }
end

@[norm_cast]
lemma int_coe_rising_factorial {r : ℤ} {n : ℕ} :
  ((rising_factorial r n : ℤ) : R) = rising_factorial (r : R) n :=
by rw [←int.coe_cast_ring_hom, map_rising_factorial]

@[norm_cast]
lemma int_coe_falling_factorial {r : ℤ} {n : ℕ} :
  ((falling_factorial r n : ℤ) : R) = falling_factorial (r : R) n :=
by rw [←int.coe_cast_ring_hom, map_falling_factorial]

end
end ring_hom
