/-
Copyright (c) 2020 Yury Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury Kudryashov
-/

import algebra.group_power
import logic.function.iterate
import group_theory.perm.basic

/-!
# Iterates of monoid and ring homomorphisms

Iterate of a monoid/ring homomorphism is a monoid/ring homomorphism but it has a wrong type, so Lean
can't apply lemmas like `monoid_hom.map_one` to `f^[n] 1`. Though it is possible to define
a monoid structure on the endomorphisms, quite often we do not want to convert from
`M →* M` to (not yet defined) `monoid.End M` and from `f^[n]` to `f^n` just to apply a simple lemma.

So, we restate standard `*_hom.map_*` lemmas under names `*_hom.iterate_map_*`.

We also prove formulas for iterates of add/mul left/right.

## Tags

homomorphism, iterate
-/

open function

variables {M : Type*} {N : Type*} {G : Type*} {H : Type*}

/-- An auxiliary lemma that can be used to prove `⇑(f ^ n) = (⇑f^[n])`. -/
lemma hom_coe_pow {F : Type*} [monoid F] (c : F → M → M) (h1 : c 1 = id)
  (hmul : ∀ f g, c (f * g) = c f ∘ c g) (f : F) : ∀ n, c (f ^ n) = (c f^[n])
| 0 := h1
| (n + 1) := by rw [pow_succ, iterate_succ', hmul, hom_coe_pow]

namespace monoid_hom

variables [monoid M] [monoid N] [group G] [group H]

@[simp, to_additive]
theorem iterate_map_one (f : M →* M) (n : ℕ) : f^[n] 1 = 1 :=
iterate_fixed f.map_one n

@[simp, to_additive]
theorem iterate_map_mul (f : M →* M) (n : ℕ) (x y) :
  f^[n] (x * y) = (f^[n] x) * (f^[n] y) :=
semiconj₂.iterate f.map_mul n x y

@[simp, to_additive]
theorem iterate_map_inv (f : G →* G) (n : ℕ) (x) :
  f^[n] (x⁻¹) = (f^[n] x)⁻¹ :=
commute.iterate_left f.map_inv n x

theorem iterate_map_pow (f : M →* M) (a) (n m : ℕ) : f^[n] (a^m) = (f^[n] a)^m :=
commute.iterate_left (λ x, f.map_pow x m) n a

theorem iterate_map_gpow (f : G →* G) (a) (n : ℕ) (m : ℤ) : f^[n] (a^m) = (f^[n] a)^m :=
commute.iterate_left (λ x, f.map_gpow x m) n a

lemma coe_pow {M} [comm_monoid M] (f : monoid.End M) (n : ℕ) : ⇑(f^n) = (f^[n]) :=
hom_coe_pow _ rfl (λ f g, rfl) _ _

end monoid_hom

namespace add_monoid_hom

variables [add_monoid M] [add_monoid N] [add_group G] [add_group H]

@[simp]
theorem iterate_map_sub (f : G →+ G) (n : ℕ) (x y) :
  f^[n] (x - y) = (f^[n] x) - (f^[n] y) :=
semiconj₂.iterate f.map_sub n x y

theorem iterate_map_smul (f : M →+ M) (n m : ℕ) (x : M) :
  f^[n] (m •ℕ x) = m •ℕ (f^[n] x) :=
f.to_multiplicative.iterate_map_pow x n m

theorem iterate_map_gsmul (f : G →+ G) (n : ℕ) (m : ℤ) (x : G) :
  f^[n] (m •ℤ x) = m •ℤ (f^[n] x) :=
f.to_multiplicative.iterate_map_gpow x n m

end add_monoid_hom

namespace ring_hom

section semiring

variables {R : Type*} [semiring R] (f : R →+* R) (n : ℕ) (x y : R)

lemma coe_pow (n : ℕ) : ⇑(f^n) = (f^[n]) :=
hom_coe_pow _ rfl (λ f g, rfl) f n

theorem iterate_map_one : f^[n] 1 = 1 := f.to_monoid_hom.iterate_map_one n

theorem iterate_map_zero : f^[n] 0 = 0 := f.to_add_monoid_hom.iterate_map_zero n

theorem iterate_map_add : f^[n] (x + y) = (f^[n] x) + (f^[n] y) :=
f.to_add_monoid_hom.iterate_map_add n x y

theorem iterate_map_mul : f^[n] (x * y) = (f^[n] x) * (f^[n] y) :=
f.to_monoid_hom.iterate_map_mul n x y

theorem iterate_map_pow (a) (n m : ℕ) : f^[n] (a^m) = (f^[n] a)^m :=
f.to_monoid_hom.iterate_map_pow a n m

theorem iterate_map_smul (n m : ℕ) (x : R) :
  f^[n] (m •ℕ x) = m •ℕ (f^[n] x) :=
f.to_add_monoid_hom.iterate_map_smul n m x

end semiring

variables {R : Type*} [ring R] (f : R →+* R) (n : ℕ) (x y : R)

theorem iterate_map_sub : f^[n] (x - y) = (f^[n] x) - (f^[n] y) :=
f.to_add_monoid_hom.iterate_map_sub n x y

theorem iterate_map_neg : f^[n] (-x) = -(f^[n] x) :=
f.to_add_monoid_hom.iterate_map_neg n x

theorem iterate_map_gsmul (n : ℕ) (m : ℤ) (x : R) :
  f^[n] (m •ℤ x) = m •ℤ (f^[n] x) :=
f.to_add_monoid_hom.iterate_map_gsmul n m x

end ring_hom

lemma equiv.perm.coe_pow {α : Type*} (f : equiv.perm α) (n : ℕ) : ⇑(f ^ n) = (f^[n]) :=
hom_coe_pow _ rfl (λ _ _, rfl) _ _

@[simp] lemma mul_left_iterate [monoid M] (a : M) (n : ℕ) : ((*) a)^[n] = (*) (a^n) :=
nat.rec_on n (funext $ λ x, by simp) $ λ n ihn,
funext $ λ x, by simp [iterate_succ, ihn, pow_succ', mul_assoc]

@[simp] lemma add_left_iterate [add_monoid M] (a : M) (n : ℕ) : ((+) a)^[n] = (+) (n •ℕ a) :=
@mul_left_iterate (multiplicative M) _ a n

@[simp] lemma mul_right_iterate [monoid M] (a : M) (n : ℕ) :
  (λ x, x * a)^[n] = (λ x, x * a^n) :=
nat.rec_on n (funext $ λ x, by simp) $ λ n ihn,
funext $ λ x, by simp [iterate_succ, ihn, pow_succ, mul_assoc]

@[simp] lemma add_right_iterate [add_monoid M] (a : M) (n : ℕ) :
  (λ x, x + a)^[n] = λ x, x + (n •ℕ a) :=
@mul_right_iterate (multiplicative M) _ a n
