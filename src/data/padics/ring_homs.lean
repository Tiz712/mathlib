/-
Copyright (c) 2020 Johan Commelin and Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin and Robert Y. Lewis
-/

import data.padics.padic_integers

/-!

# Relating `ℤ_[p]` to `zmod p`


* has a ring hom to `ℤ/p^nℤ` for each `n`
* `to_zmod`: ring hom to `ℤ/pℤ`
* `to_zmod_pow` : ring hom to `ℤ/p^nℤ`

-/

noncomputable theory
open_locale classical
namespace padic_int
open nat local_ring padic

variables {p : ℕ} [hp_prime : fact (p.prime)]
include hp_prime

section
/-! ### Ring homomorphisms to `zmod p` and `zmod (p ^ n)` -/
variables (p) (r : ℚ)

omit hp_prime
/--
`mod_part p r` is an integer that satisfies
`∥(r - mod_part p r : ℚ_[p])∥ < 1` when `∥(r : ℚ_[p])∥ ≤ 1`,
see `padic_int.norm_sub_mod_part`.
It is the unique non-negative integer that is `< p` with this property.

(Note that this definition assumes `r : ℚ`.
See `padic_int.zmod_repr` for a version that takes values in `ℕ`
and works for arbitrary `x : ℤ_[p]`.) -/
def mod_part : ℤ :=
(r.num * gcd_a r.denom p) % p

include hp_prime

variable {p}
lemma mod_part_lt_p : mod_part p r < p :=
begin
  convert int.mod_lt _ _,
  { simp },
  { exact_mod_cast hp_prime.ne_zero }
end

lemma mod_part_nonneg : 0 ≤ mod_part p r :=
int.mod_nonneg _ $ by exact_mod_cast hp_prime.ne_zero

lemma is_unit_denom (r : ℚ) (h : ∥(r : ℚ_[p])∥ ≤ 1) : is_unit (r.denom : ℤ_[p]) :=
begin
  rw is_unit_iff,
  apply le_antisymm (r.denom : ℤ_[p]).2,
  rw [← not_lt, val_eq_coe, coe_coe],
  intro norm_denom_lt,
  have hr : ∥(r * r.denom : ℚ_[p])∥ = ∥(r.num : ℚ_[p])∥,
  { rw_mod_cast @rat.mul_denom_eq_num r, refl, },
  rw padic_norm_e.mul at hr,
  have key : ∥(r.num : ℚ_[p])∥ < 1,
  { calc _ = _ : hr.symm
    ... < 1 * 1 : _
    ... = 1 : mul_one 1,
    apply mul_lt_mul' h norm_denom_lt (norm_nonneg _) zero_lt_one, },
  have : ↑p ∣ r.num ∧ (p : ℤ) ∣ r.denom,
  { simp only [← norm_int_lt_one_iff_dvd, ← padic_norm_e_of_padic_int],
    norm_cast, exact ⟨key, norm_denom_lt⟩ },
  apply hp_prime.not_dvd_one,
  rwa [← r.cop.gcd_eq_one, nat.dvd_gcd_iff, ← int.coe_nat_dvd_left, ← int.coe_nat_dvd],
end

lemma norm_sub_mod_part_aux (r : ℚ) (h : ∥(r : ℚ_[p])∥ ≤ 1) :
  ↑p ∣ r.num - r.num * r.denom.gcd_a p % p * ↑(r.denom) :=
begin
  rw ← zmod.int_coe_zmod_eq_zero_iff_dvd,
  simp only [int.cast_coe_nat, zmod.cast_mod_nat p, int.cast_mul, int.cast_sub],
  have := congr_arg (coe : ℤ → zmod p) (gcd_eq_gcd_ab r.denom p),
  simp only [int.cast_coe_nat, add_zero, int.cast_add, zmod.cast_self, int.cast_mul, zero_mul] at this,
  push_cast,
  rw [mul_right_comm, mul_assoc, ←this],
  suffices rdcp : r.denom.coprime p,
  { rw rdcp.gcd_eq_one, simp only [mul_one, cast_one, sub_self], },
  apply coprime.symm,
  apply (coprime_or_dvd_of_prime ‹_› _).resolve_right,
  rw [← int.coe_nat_dvd, ← norm_int_lt_one_iff_dvd, not_lt],
  apply ge_of_eq,
  rw ← is_unit_iff,
  exact is_unit_denom r h,
end

lemma norm_sub_mod_part (h : ∥(r : ℚ_[p])∥ ≤ 1) : ∥(⟨r,h⟩ - mod_part p r : ℤ_[p])∥ < 1 :=
begin
  let n := mod_part p r,
  by_cases aux : (⟨r,h⟩ - n : ℤ_[p]) = 0,
  { rw [aux, norm_zero], exact zero_lt_one, },
  rw [norm_lt_one_iff_dvd, ← (is_unit_denom r h).dvd_mul_right],
  suffices : ↑p ∣ r.num - n * r.denom,
  { convert (int.cast_ring_hom ℤ_[p]).map_dvd this,
    simp only [sub_mul, int.cast_coe_nat, ring_hom.eq_int_cast, int.cast_mul,
      sub_left_inj, int.cast_sub],
    apply subtype.coe_injective,
    simp only [coe_mul, subtype.coe_mk, coe_coe],
    rw_mod_cast @rat.mul_denom_eq_num r, refl },
  dsimp [n, mod_part],
  apply norm_sub_mod_part_aux r h,
end

lemma exists_mem_range_of_norm_rat_le_one (h : ∥(r : ℚ_[p])∥ ≤ 1) :
  ∃ n : ℤ, 0 ≤ n ∧ n < p ∧ ∥(⟨r,h⟩ - n : ℤ_[p])∥ < 1 :=
⟨mod_part p r, mod_part_nonneg _, mod_part_lt_p _, norm_sub_mod_part _ h⟩

end

section

lemma zmod_congr_of_sub_mem_span_aux (n : ℕ) (x : ℤ_[p]) (a b : ℤ)
  (ha : x - a ∈ (ideal.span {p ^ n} : ideal ℤ_[p]))
  (hb : x - b ∈ (ideal.span {p ^ n} : ideal ℤ_[p])) :
  (a : zmod (p ^ n)) = b :=
begin
  rw [ideal.mem_span_singleton] at ha hb,
  rw [← sub_eq_zero, ← int.cast_sub,
      zmod.int_coe_zmod_eq_zero_iff_dvd, int.coe_nat_pow],
  rw [← dvd_neg, neg_sub] at ha,
  have := dvd_add ha hb,
  rwa [sub_eq_add_neg, sub_eq_add_neg, add_assoc, neg_add_cancel_left,
      ← sub_eq_add_neg, ← int.cast_sub, pow_p_dvd_int_iff] at this,
end

lemma zmod_congr_of_sub_mem_span (n : ℕ) (x : ℤ_[p]) (a b : ℕ)
  (ha : x - a ∈ (ideal.span {p ^ n} : ideal ℤ_[p]))
  (hb : x - b ∈ (ideal.span {p ^ n} : ideal ℤ_[p])) :
  (a : zmod (p ^ n)) = b :=
zmod_congr_of_sub_mem_span_aux n x a b ha hb

lemma zmod_congr_of_sub_mem_max_ideal (x : ℤ_[p]) (m n : ℕ)
  (hm : x - m ∈ maximal_ideal ℤ_[p]) (hn : x - n ∈ maximal_ideal ℤ_[p]) :
  (m : zmod p) = n :=
begin
  rw maximal_ideal_eq_span_p at hm hn,
  have := zmod_congr_of_sub_mem_span_aux 1 x m n,
  simp only [_root_.pow_one] at this,
  specialize this hm hn,
  apply_fun zmod.cast_hom (show p ∣ p ^ 1, by rw nat.pow_one) (zmod p) at this,
  simpa only [ring_hom.map_int_cast],
end

variable (x : ℤ_[p])
lemma exists_mem_range : ∃ n : ℕ, n < p ∧ (x - n ∈ maximal_ideal ℤ_[p]) :=
begin
  simp only [maximal_ideal_eq_span_p, ideal.mem_span_singleton, ← norm_lt_one_iff_dvd],
  obtain ⟨r, hr⟩ := rat_dense (x : ℚ_[p]) zero_lt_one,
  have H : ∥(r : ℚ_[p])∥ ≤ 1,
  { rw norm_sub_rev at hr,
    rw show (r : ℚ_[p]) = (r - x) + x, by ring,
    apply le_trans (padic_norm_e.nonarchimedean _ _),
    apply max_le (le_of_lt hr) x.2, },
  obtain ⟨n, hzn, hnp, hn⟩ := exists_mem_range_of_norm_rat_le_one r H,
  lift n to ℕ using hzn,
  use [n],
  split, {exact_mod_cast hnp},
  simp only [norm_def, coe_sub, subtype.coe_mk, coe_coe] at hn ⊢,
  rw show (x - n : ℚ_[p]) = (x - r) + (r - n), by ring,
  apply lt_of_le_of_lt (padic_norm_e.nonarchimedean _ _),
  apply max_lt hr,
  simpa using hn
end

/--
`zmod_repr x` is the unique natural number smaller than `p`
satisfying `∥(x - zmod_repr x : ℤ_[p])∥ < 1`.
-/
def zmod_repr : ℕ :=
classical.some (exists_mem_range x)

lemma zmod_repr_spec : zmod_repr x < p ∧ (x - zmod_repr x ∈ maximal_ideal ℤ_[p]) :=
classical.some_spec (exists_mem_range x)

lemma zmod_repr_lt_p : zmod_repr x < p := (zmod_repr_spec _).1

lemma sub_zmod_repr_mem : (x - zmod_repr x ∈ maximal_ideal ℤ_[p]) := (zmod_repr_spec _).2

end

/--
`to_zmod_hom` is an auxiliary constructor for creating ring homs from `ℤ_[p]` to `zmod v`.
-/
def to_zmod_hom (v : ℕ) (f : ℤ_[p] → ℕ) (f_spec : ∀ x, x - f x ∈ (ideal.span {v} : ideal ℤ_[p]))
  (f_congr : ∀ (x : ℤ_[p]) (a b : ℕ),
     x - a ∈ (ideal.span {v} : ideal ℤ_[p]) → x - b ∈ (ideal.span {v} : ideal ℤ_[p]) →
       (a : zmod v) = b) :
  ℤ_[p] →+* zmod v :=
{ to_fun := λ x, f x,
  map_zero' :=
  begin
    rw [f_congr (0 : ℤ_[p]) _ 0, cast_zero],
    { exact f_spec _ },
    { simp only [sub_zero, cast_zero, submodule.zero_mem], }
  end,
  map_one' :=
  begin
    rw [f_congr (1 : ℤ_[p]) _ 1, cast_one],
    { exact f_spec _ },
    { simp only [sub_self, cast_one, submodule.zero_mem], }
  end,
  map_add' :=
  begin
    intros x y,
    rw [f_congr (x + y) _ (f x + f y), cast_add],
    { exact f_spec _ },
    { convert ideal.add_mem _ (f_spec x) (f_spec y),
      rw cast_add,
      ring, }
  end,
  map_mul' :=
  begin
    intros x y,
    rw [f_congr (x * y) _ (f x * f y), cast_mul],
    { exact f_spec _ },
    { let I : ideal ℤ_[p] := ideal.span {v},
      have A : x * (y - f y) ∈ I := I.mul_mem_left (f_spec _),
      have B : (x - f x) * (f y) ∈ I := I.mul_mem_right (f_spec _),
      convert I.add_mem A B,
      rw cast_mul,
      ring, }
  end, }

/--
`to_zmod` is a ring hom from `ℤ_[p]` to `zmod p`,
with the equality `to_zmod x = (zmod_repr x : zmod p)`.
-/
def to_zmod : ℤ_[p] →+* zmod p :=
to_zmod_hom p zmod_repr
  (by { rw ←maximal_ideal_eq_span_p, exact sub_zmod_repr_mem })
  (by { rw ←maximal_ideal_eq_span_p, exact zmod_congr_of_sub_mem_max_ideal } )

/--
`z - (to_zmod z : ℤ_[p])` is contained in the maximal ideal of `ℤ_[p]`, for every `z : ℤ_[p]`.

The coercion from `zmod p` to `ℤ_[p]` is `zmod.has_coe_t`,
which coerces `zmod p` into artibrary rings.
This is unfortunate, but a consequence of the fact that we allow `zmod p`
to coerce to rings of arbitrary characteristic, instead of only rings of characteristic `p`.
This coercion is only a ring homomorphism if it coerces into a ring whose characteristic divides `p`.
While this is not the case here we can still make use of the coercion.
-/
lemma to_zmod_spec (z : ℤ_[p]) : z - (to_zmod z : ℤ_[p]) ∈ maximal_ideal ℤ_[p] :=
begin
  convert sub_zmod_repr_mem z using 2,
  dsimp [to_zmod, to_zmod_hom],
  unfreezingI { rcases (exists_eq_add_of_lt (hp_prime.pos)) with ⟨p', rfl⟩ },
  change ↑(zmod.val _) = _,
  simp [zmod.val_cast_nat],
  rw mod_eq_of_lt,
  simpa only [zero_add] using zmod_repr_lt_p z,
end

lemma ker_to_zmod : (to_zmod : ℤ_[p] →+* zmod p).ker = maximal_ideal ℤ_[p] :=
begin
  ext x,
  rw ring_hom.mem_ker,
  split,
  { intro h,
    simpa only [h, zmod.cast_zero, sub_zero] using to_zmod_spec x, },
  { intro h,
    rw ← sub_zero x at h,
    dsimp [to_zmod, to_zmod_hom],
    convert zmod_congr_of_sub_mem_max_ideal x _ 0 _ h,
    apply sub_zmod_repr_mem, }
end

/-- `appr n x` gives a value `v : ℕ` such that `x` and `↑v : ℤ_p` are congruent mod `p^n`.
See `appr_spec`. -/
-- TODO: prove that `x.appr` is a sequence that tends to `x`.
-- Possibly relevant: summable_iff_vanishing_norm
noncomputable def appr : ℤ_[p] → ℕ → ℕ
| x 0     := 0
| x (n+1) :=
let y := x - appr x n in
if hy : y = 0 then
  appr x n
else
  let u := unit_coeff hy in
  appr x n + p ^ n * (to_zmod ((u : ℤ_[p]) * (p ^ (y.valuation - n).nat_abs))).val

lemma appr_lt (x : ℤ_[p]) (n : ℕ) : x.appr n < p ^ n :=
begin
  induction n with n ih generalizing x,
  { simp only [appr, succ_pos', nat.pow_zero], },
  simp only [appr, ring_hom.map_nat_cast, zmod.cast_self, ring_hom.map_pow, int.nat_abs, ring_hom.map_mul],
  have hp : p ^ n < p ^ (n + 1),
  { simp [← nat.pow_eq_pow],
    apply pow_lt_pow hp_prime.one_lt (lt_add_one n) },
  split_ifs with h,
  { apply lt_trans (ih _) hp, },
  { calc _ < p ^ n + p ^ n * (p - 1) : _
    ... = p ^ (n + 1) : _,
    { apply add_lt_add_of_lt_of_le (ih _),
      apply nat.mul_le_mul_left,
      apply le_pred_of_lt,
      apply zmod.val_lt },
    { rw [nat.mul_sub_left_distrib, mul_one, ← nat.pow_succ],
      apply nat.add_sub_cancel' (le_of_lt hp) } }
end

lemma appr_mono (x : ℤ_[p]) : monotone x.appr :=
begin
  apply monotone_of_monotone_nat,
  intro n,
  dsimp [appr],
  split_ifs, { refl, },
  apply nat.le_add_right,
end

lemma dvd_appr_sub_appr (x : ℤ_[p]) (m n : ℕ) (h : m ≤ n) :
  p ^ m ∣ x.appr n - x.appr m :=
begin
  obtain ⟨k, rfl⟩ := nat.exists_eq_add_of_le h, clear h,
  induction k with k ih,
  { simp only [add_zero, nat.sub_self, dvd_zero], },
  rw [nat.succ_eq_add_one, ← add_assoc],
  dsimp [appr],
  split_ifs with h,
  { exact ih },
  rw [add_comm, nat.add_sub_assoc (appr_mono _ (nat.le_add_right m k))],
  apply dvd_add _ ih,
  apply dvd_mul_of_dvd_left,
  apply nat.pow_dvd_pow _ (nat.le_add_right m k),
end

lemma appr_spec (n : ℕ) : ∀ (x : ℤ_[p]), x - appr x n ∈ (ideal.span {p^n} : ideal ℤ_[p]) :=
begin
  simp only [ideal.mem_span_singleton],
  induction n with n ih,
  { simp only [is_unit_one, is_unit.dvd, pow_zero, forall_true_iff], },
  { intro x,
    dsimp only [appr],
    split_ifs with h,
    { rw h, apply dvd_zero },
    { push_cast, rw sub_add_eq_sub_sub,
      obtain ⟨c, hc⟩ := ih x,
      simp only [ring_hom.map_nat_cast, zmod.cast_self, ring_hom.map_pow, ring_hom.map_mul, zmod.nat_cast_val],
      have hc' : c ≠ 0,
      { rintro rfl, simp only [mul_zero] at hc, contradiction },
      conv_rhs { congr, simp only [hc], },
      rw show (x - ↑(appr x n)).valuation = (↑p ^ n * c).valuation,
      { rw hc },
      rw [valuation_p_pow_mul _ _ hc', add_sub_cancel', pow_succ', ← mul_sub],
      apply mul_dvd_mul_left,
      by_cases hc0 : c.valuation.nat_abs = 0,
      { simp only [hc0, mul_one, pow_zero],
        rw [mul_comm, unit_coeff_spec h] at hc,
        suffices : c = unit_coeff h,
        { rw [← this, ← ideal.mem_span_singleton, ← maximal_ideal_eq_span_p],
          apply to_zmod_spec },
        obtain ⟨c, rfl⟩ : is_unit c, -- TODO: write a can_lift instance for units
        { rw int.nat_abs_eq_zero at hc0,
          rw [is_unit_iff, norm_eq_pow_val hc', hc0, neg_zero, fpow_zero], },
        rw discrete_valuation_ring.unit_mul_pow_congr_unit _ _ _ _ _ hc,
        exact irreducible_p },
      { rw [_root_.zero_pow (nat.pos_of_ne_zero hc0)],
        simp only [sub_zero, zmod.cast_zero, mul_zero],
        rw unit_coeff_spec hc',
        apply dvd_mul_of_dvd_right,
        apply dvd_pow (dvd_refl _),
        exact hc0 } } }
end

/-- A ring hom from `ℤ_[p]` to `zmod (p^n)`, with underlying function `padic_int.appr n`. -/
def to_zmod_pow (n : ℕ) : ℤ_[p] →+* zmod (p ^ n) :=
to_zmod_hom (p^n) (λ x, appr x n)
  (by { intros, convert appr_spec n _ using 1, simp })
  (by { intros x a b ha hb,
        apply zmod_congr_of_sub_mem_span n x a b; [simpa using ha, simpa using hb] })

lemma ker_to_zmod_pow (n : ℕ) : (to_zmod_pow n : ℤ_[p] →+* zmod (p ^ n)).ker = ideal.span {p ^ n} :=
begin
  ext x,
  rw ring_hom.mem_ker,
  split,
  { intro h,
    suffices : x.appr n = 0,
    { convert appr_spec n x, simp only [this, sub_zero, cast_zero], },
    dsimp [to_zmod_pow, to_zmod_hom] at h,
    rw zmod.nat_coe_zmod_eq_zero_iff_dvd at h,
    apply eq_zero_of_dvd_of_lt h (appr_lt _ _),  },
  { intro h,
    rw ← sub_zero x at h,
    dsimp [to_zmod_pow, to_zmod_hom],
    rw [zmod_congr_of_sub_mem_span n x _ 0 _ h, cast_zero],
    apply appr_spec, }
end

@[simp] lemma zmod_cast_comp_to_zmod_pow (m n : ℕ) (h : m ≤ n) :
  (zmod.cast_hom (nat.pow_dvd_pow p h) (zmod (p ^ m))).comp (to_zmod_pow n) = to_zmod_pow m :=
begin
  apply zmod.ring_hom_eq_of_ker_eq,
  ext x,
  rw [ring_hom.mem_ker, ring_hom.mem_ker],
  simp only [function.comp_app, zmod.cast_hom_apply, ring_hom.coe_comp],
  simp only [to_zmod_pow, to_zmod_hom, ring_hom.coe_mk],
  rw [zmod.cast_nat_cast (nat.pow_dvd_pow p h),
      zmod_congr_of_sub_mem_span m (x.appr n) (x.appr n) (x.appr m)],
  { rw [sub_self], apply ideal.zero_mem _, },
  { rw ideal.mem_span_singleton,
    rcases dvd_appr_sub_appr x m n h with ⟨c, hc⟩,
    use c,
    rw [← nat.cast_sub (appr_mono _ h), hc, nat.cast_mul, nat.cast_pow], },
  { apply_instance }
end

@[simp] lemma cast_to_zmod_pow (m n : ℕ) (h : m ≤ n) (x : ℤ_[p]) :
  ↑(to_zmod_pow n x) = to_zmod_pow m x :=
by { rw ← zmod_cast_comp_to_zmod_pow _ _ h, refl }

lemma dense_range_nat_cast :
  dense_range (nat.cast : ℕ → ℤ_[p]) :=
begin
  intro x,
  rw metric.mem_closure_range_iff,
  intros ε hε,
  obtain ⟨n, hn⟩ := exists_pow_neg_lt p hε,
  use (x.appr n),
  rw dist_eq_norm,
  apply lt_of_le_of_lt _ hn,
  rw norm_le_pow_iff_mem_span_pow,
  apply appr_spec,
end

lemma dense_range_int_cast :
  dense_range (int.cast : ℤ → ℤ_[p]) :=
begin
  intro x,
  apply dense_range_nat_cast.induction_on x,
  { exact is_closed_closure, },
  { intro a,
    change (a.cast : ℤ_[p]) with (a : ℤ).cast,
    apply subset_closure,
    exact set.mem_range_self _ }
end

section lift
/-! ### Universal property as projective limit -/

open cau_seq padic_seq

variables {R : Type*} [comm_ring R] (f : Π k : ℕ, R →+* zmod (p^k))
  (f_compat : ∀ k1 k2 (hk : k1 ≤ k2), (zmod.cast_hom (nat.pow_dvd_pow p hk) _).comp (f k2) = f k1)

omit hp_prime

/--
Given a family of ring homs `f : Π k : ℕ, R →+* zmod (p^k)`,
`nth_hom f r` is an integer-valued sequence
whose `n`th value is `f n r`.
-/
def nth_hom (r : R) : ℕ → ℤ :=
λ n, (f n r : zmod (p^n)).val

@[simp] lemma nth_hom_zero : nth_hom f 0 = 0 :=
by simp [nth_hom]; refl

variable {f}

include hp_prime
include f_compat

lemma pow_dvd_nth_hom_sub (r : R) (i j : ℕ) (h : i ≤ j) :
  ↑p ^ i ∣ nth_hom f r j - nth_hom f r i :=
begin
  specialize f_compat (i) (j) h,
  rw [← int.coe_nat_pow, ← zmod.int_coe_zmod_eq_zero_iff_dvd],
  rw [int.cast_sub],
  dsimp [nth_hom],
  rw [← f_compat, ring_hom.comp_apply],
  have : fact (p ^ (i) > 0) := pow_pos (nat.prime.pos ‹_›) _,
  have : fact (p ^ (j) > 0) := pow_pos (nat.prime.pos ‹_›) _,
  unfreezingI { simp only [zmod.cast_id, zmod.cast_hom_apply, sub_self, zmod.nat_cast_val], },
end

lemma is_cau_seq_nth_hom (r : R): is_cau_seq (padic_norm p) (λ n, nth_hom f r n) :=
begin
  intros ε hε,
  obtain ⟨k, hk⟩ : ∃ k : ℕ, (p ^ - (↑(k : ℕ) : ℤ) : ℚ) < ε := exists_pow_neg_lt_rat p hε,
  use k,
  intros j hj,
  refine lt_of_le_of_lt _ hk,
  norm_cast,
  rw ← padic_norm.dvd_iff_norm_le,
  exact_mod_cast pow_dvd_nth_hom_sub f_compat r k j hj
end

/--
`nth_hom_seq f_compat r` bundles `padic_int.nth_hom f r`
as a Cauchy sequence of rationals with respect to the `p`-adic norm.
The `n`th value of the sequence is `((f n r : ℤ) : ℚ)`.
-/
def nth_hom_seq (r : R) : padic_seq p := ⟨λ n, nth_hom f r n, is_cau_seq_nth_hom f_compat r⟩

lemma nth_hom_seq_one : nth_hom_seq f_compat 1 ≈ 1 :=
begin
  intros ε hε,
  change _ < _ at hε,
  use 1,
  intros j hj,
  haveI : fact (1 < p^j) := nat.one_lt_pow _ _ (by linarith) (nat.prime.one_lt ‹_›),
  simp [nth_hom_seq, nth_hom, zmod.val_one, hε],
end

lemma nth_hom_seq_add (r s : R) :
  nth_hom_seq f_compat (r + s) ≈ nth_hom_seq f_compat r + nth_hom_seq f_compat s :=
begin
  intros ε hε,
  obtain ⟨n, hn⟩ := exists_pow_neg_lt_rat p hε,
  use n,
  intros j hj,
  dsimp [nth_hom_seq],
  apply lt_of_le_of_lt _ hn,
  rw [← int.cast_add, ← int.cast_sub, ← padic_norm.dvd_iff_norm_le],
  rw ← zmod.int_coe_zmod_eq_zero_iff_dvd,
  dsimp [nth_hom],
  have : fact (p ^ n > 0) := pow_pos (nat.prime.pos ‹_›) _,
  have : fact (p ^ j > 0) := pow_pos (nat.prime.pos ‹_›) _,
  unfreezingI
  { simp only [int.cast_coe_nat, int.cast_add, ring_hom.map_add, int.cast_sub, zmod.nat_cast_val] },
  rw [zmod.cast_add (show p ^ n ∣ p ^ j, from _), sub_self],
  { apply_instance },
  { apply nat.pow_dvd_pow, linarith only [hj] },
end

lemma nth_hom_seq_mul (r s : R) :
  nth_hom_seq f_compat (r * s) ≈ nth_hom_seq f_compat r * nth_hom_seq f_compat s :=
begin
  intros ε hε,
  obtain ⟨n, hn⟩ := exists_pow_neg_lt_rat p hε,
  use n,
  intros j hj,
  dsimp [nth_hom_seq],
  apply lt_of_le_of_lt _ hn,
  rw [← int.cast_mul, ← int.cast_sub, ← padic_norm.dvd_iff_norm_le],
  rw ← zmod.int_coe_zmod_eq_zero_iff_dvd,
  dsimp [nth_hom],
  have : fact (p ^ n > 0) := pow_pos (nat.prime.pos ‹_›) _,
  have : fact (p ^ j > 0) := pow_pos (nat.prime.pos ‹_›) _,
  unfreezingI
  { simp only [int.cast_coe_nat, int.cast_mul, int.cast_sub, ring_hom.map_mul, zmod.nat_cast_val] },
  rw [zmod.cast_mul (show p ^ n ∣ p ^ j, from _), sub_self],
  { apply_instance },
  { apply nat.pow_dvd_pow, linarith only [hj] },
end

/--
`lim_nth_hom f_compat r` is the limit of a sequence `f` of compatible ring homs `R →+* zmod (p^k)`.
This is itself a ring hom: see `paic_int.lift`.
-/
def lim_nth_hom (r : R) : ℤ_[p] :=
of_int_seq (nth_hom f r) (is_cau_seq_nth_hom f_compat r)

lemma lim_nth_hom_spec (r : R) :
  ∀ ε : ℝ, 0 < ε → ∃ N : ℕ, ∀ n ≥ N, ∥lim_nth_hom f_compat r - nth_hom f r n∥ < ε :=
begin
  intros ε hε,
  obtain ⟨ε', hε'0, hε'⟩ : ∃ v : ℚ, (0 : ℝ) < v ∧ ↑v < ε := exists_rat_btwn hε,
  norm_cast at hε'0,
  obtain ⟨N, hN⟩ := padic_norm_e.defn (nth_hom_seq f_compat r) hε'0,
  use N,
  intros n hn,
  apply lt.trans _ hε',
  change ↑(padic_norm_e _) < _,
  norm_cast,
  convert hN _ hn,
  simp [nth_hom, lim_nth_hom, nth_hom_seq, of_int_seq],
end

lemma lim_nth_hom_zero : lim_nth_hom f_compat 0 = 0 :=
by simp [lim_nth_hom]; refl

lemma lim_nth_hom_one : lim_nth_hom f_compat 1 = 1 :=
subtype.ext $ quot.sound $ nth_hom_seq_one _

lemma lim_nth_hom_add (r s : R) : lim_nth_hom f_compat (r + s) = lim_nth_hom f_compat r + lim_nth_hom f_compat s :=
subtype.ext $ quot.sound $ nth_hom_seq_add _ _ _

lemma lim_nth_hom_mul (r s : R) : lim_nth_hom f_compat (r * s) = lim_nth_hom f_compat r * lim_nth_hom f_compat s :=
subtype.ext $ quot.sound $ nth_hom_seq_mul _ _ _

-- TODO: generalize this to arbitrary complete discrete valuation rings
/--
`lift f_compat` is the limit of a sequence `f` of compatible ring homs `R →+* zmod (p^k)`,
with the equality `lift f_compat r = `padic_int.lim_nth_hom f_compat r`.
-/
def lift : R →+* ℤ_[p] :=
{ to_fun := lim_nth_hom f_compat,
  map_one' := lim_nth_hom_one f_compat,
  map_mul' := lim_nth_hom_mul f_compat,
  map_zero' := lim_nth_hom_zero f_compat,
  map_add' := lim_nth_hom_add f_compat }

omit f_compat

lemma lift_sub_val_mem_span (r : R) (n : ℕ) :
  (lift f_compat r - (f n r).val) ∈ (ideal.span {↑p ^ n} : ideal ℤ_[p]) :=
begin
  obtain ⟨k, hk⟩ := lim_nth_hom_spec f_compat r _ (show (0 : ℝ) < p ^ (-n : ℤ), from _),
  swap,
  { rw [fpow_neg, inv_pos, fpow_coe_nat],
    apply _root_.pow_pos, exact_mod_cast nat.prime.pos ‹_› },
  specialize hk (max n k) (le_max_right _ _),
  have := le_of_lt hk,
  rw norm_le_pow_iff_mem_span_pow at this,
  dsimp at this,
  dsimp [lift],
  rw sub_eq_sub_add_sub (lim_nth_hom f_compat r) _ ↑(nth_hom f r (max n k)),
  apply ideal.add_mem _ _ this,
  have := pow_dvd_nth_hom_sub f_compat r n (max n k) (le_max_left _ _),
  rw ideal.mem_span_singleton,
  rw show (p ^ n : ℤ_[p]) = (p ^ n : ℤ),
  { norm_cast },
  convert (int.cast_ring_hom ℤ_[p]).map_dvd (dvd.trans _ this),
  { simp only [nth_hom, int.cast_coe_nat, ring_hom.eq_int_cast, cast_inj, sub_right_inj, int.cast_sub], },
  { refl }
end

/--
One part of the universal property of `ℤ_[p]` as a projective limit.
See also `padic_int.lift_unique`.
-/
lemma lift_spec (n : ℕ) : (to_zmod_pow n).comp (lift f_compat) = f n :=
begin
  ext r,
  haveI : fact (0 < p ^ n) := nat.pow_pos (nat.prime.pos ‹_›) n,
  rw [ring_hom.comp_apply, ← zmod.cast_val (f n r), ← (to_zmod_pow n).map_nat_cast,
      ← sub_eq_zero, ← ring_hom.map_sub, ← ring_hom.mem_ker, ker_to_zmod_pow],
  apply lift_sub_val_mem_span,
end

/--
One part of the universal property of `ℤ_[p]` as a projective limit.
See also `padic_int.lift_spec`.
-/
lemma lift_unique (g : R →+* ℤ_[p]) (hg : ∀ n, (to_zmod_pow n).comp g = f n) :
  lift f_compat = g :=
begin
  ext1 r,
  apply eq_of_forall_dist_le,
  intros ε hε,
  obtain ⟨n, hn⟩ := exists_pow_neg_lt p hε,
  apply le_trans _ (le_of_lt hn),
  rw [dist_eq_norm, norm_le_pow_iff_mem_span_pow, ← ker_to_zmod_pow, ring_hom.mem_ker,
      ring_hom.map_sub, ← ring_hom.comp_apply, ← ring_hom.comp_apply, lift_spec, hg, sub_self],
end

@[simp] lemma lift_self (z : ℤ_[p]) : @lift p _ ℤ_[p] _ to_zmod_pow
  zmod_cast_comp_to_zmod_pow z = z :=
begin
  show _ = ring_hom.id _ z,
  rw @lift_unique p _ ℤ_[p] _ _ zmod_cast_comp_to_zmod_pow (ring_hom.id ℤ_[p]),
  intro, rw ring_hom.comp_id,
end

end lift

lemma ext_of_to_zmod_pow (x y : ℤ_[p]) (h : ∀ n, to_zmod_pow n x = to_zmod_pow n y) :
  x = y :=
begin
  rw [← lift_self x, ← lift_self y],
  simp [lift, lim_nth_hom, nth_hom, h],
end

end padic_int
