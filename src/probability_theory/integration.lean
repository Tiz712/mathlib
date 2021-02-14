/-
Copyright (c) 2021 Martin Zinkevich. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Martin Zinkevich
-/
import measure_theory.measure_space
import measure_theory.borel_space
import data.indicator_function
import data.support
import measure_theory.integration
import probability_theory.independence
import tactic.split_ifs

/-!
  Integration results for independent random variables. Specifically, for two
  independent random variables X and Y over the extended non-negative
  reals, E[X * Y] = E[X] * E[Y], and similar results.
-/

noncomputable theory
open set (hiding restrict restrict_apply) filter ennreal probability_theory
open_locale classical topological_space big_operators nnreal ennreal



lemma set.indicator_mul_indicator_eq_inter {α:Type*} {t1 t2:set α} {c1 c2:ennreal}:
  (λ a, (t1.indicator (λ (x : α), c1) * t2.indicator (λ (x : α), c2)) a) =
      (λ a, (t1 ∩ t2).indicator (λ (x : α), c1 * c2) a) := begin
  simp only [zero_mul, pi.mul_apply, ite_mul, mul_ite, mul_zero],
  repeat {rw ← set.indicator}, rw [set.indicator_indicator, set.inter_comm],
end

namespace measure_theory
open measure_theory measure_theory.simple_func

/-- This (roughly) proves that if a random variable `f` is independent of an event `T`,
   then if you restrict the random variable to `T`, then
   `E[f * indicator T c 0]=E[f] * E[indicator T c 0]`. It is useful for
   `lintegral_mul_eq_lintegral_mul_lintegral_of_independent_measurable_space`. -/
lemma lintegral_mul_indicator_eq_lintegral_mul_lintegral_indicator
  {α : Type*} {Mf : measurable_space α} [M : measurable_space α] {μ : measure α} 
  (hMf : Mf ≤ M) (c : ℝ≥0∞) {T : set α} (h_meas_T : M.measurable_set' T)
  (h_ind : indep_sets Mf.measurable_set' {T} μ )
  {f : α → ℝ≥0∞} (h_meas_f : @measurable α ℝ≥0∞ Mf _ f):
   ∫⁻ a, (f * (T.indicator (λ (x : α), c))) a ∂μ =
  ∫⁻ a, f a ∂μ *
  ∫⁻ a, (T.indicator (λ (x : α), c)) a ∂μ :=
begin
  revert f,
  have h_mul_indicator : ∀ g, @measurable α ℝ≥0∞ M _ g →
    @measurable α ℝ≥0∞ M _ (g * (λ (a : α), T.indicator (λ (_x : α), c) a)) :=
  (λ g h_mg, measurable.ennreal_mul h_mg (measurable.indicator measurable_const h_meas_T)),
  apply measurable.ennreal_induction,
  { intros c' s' h_meas_s',
    rw [set.indicator_mul_indicator_eq_inter', lintegral_indicator _
        (measurable_set.inter (hMf _ h_meas_s') (h_meas_T)),
        lintegral_indicator _  (hMf _ h_meas_s'),
        lintegral_indicator _ h_meas_T],
    simp only [measurable_const, lintegral_const, set.univ_inter, lintegral_const_mul,
        measurable_set.univ, measure.restrict_apply],
    rw h_ind, ring, apply h_meas_s', simp },
  { intros f' g h_univ h_meas_f' h_meas_g h_ind_f' h_ind_g,
    have h_measM_f' := measurable.mono h_meas_f' hMf (le_refl _),
    have h_measM_g := measurable.mono h_meas_g hMf (le_refl _),
    have h_indicator : @measurable α ℝ≥0∞ M _ (λ (a : α), T.indicator (λ (_x : α), c) a),
    { apply measurable.indicator (measurable_const) h_meas_T },
    have h8 : (f' + g) * T.indicator (λ (x : α), c) =
             (λ a, (f' * (T.indicator (λ _, c))) a + (g * (T.indicator (λ _, c))) a),
    { ext1 a, simp [right_distrib] },
    rw h8,
    have h_add : (f' + g) = (λ a, (f' a + g a)),
   { refl },
   rw [h_add, lintegral_add (h_mul_indicator _ h_measM_f')
       (h_mul_indicator _ h_measM_g),
       lintegral_add h_measM_f' h_measM_g, right_distrib, h_ind_f',
       h_ind_g] },
  { intros f h_meas_f h_mono_f h_ind_f,
    have h_measM_f := (λ n, measurable.mono (h_meas_f n) hMf (le_refl _)),
    have h_mul : (λ a, ((λ (x : α), ⨆ (n : ℕ), f n x) * T.indicator (λ (x : α), c)) a) =
      (λ (a : α), ⨆ (n : ℕ), (λ (x : α), f n x * (T.indicator (λ (x : α), c) x)) a),
    { ext1 a, rw @pi.mul_apply, rw ennreal.supr_mul, },
    have h_mul2 : (λ n, ∫⁻ x, f n x * T.indicator (λ (x : α), c) x ∂μ)  =
        (λ n, (∫⁻ x, (f n x) ∂μ) * (∫⁻ x, T.indicator (λ (x : α), c) x ∂μ)),
    { ext1 n, rw ← h_ind_f n, refl },
    rw [h_mul, lintegral_supr h_measM_f h_mono_f, lintegral_supr, ennreal.supr_mul, h_mul2],
    { apply (λ n, h_mul_indicator _ (h_measM_f n)) },
    { intros m n h_le a, apply ennreal.mul_le_mul _ (le_refl _), apply h_mono_f h_le } },
end

/-- This (roughly) proves that if `f` and `g` are independent random variables,
   then `E[f * g] = E[f] * E[g]`. However, instead of directly using the independence
   of the random variables, it uses the independence of measurable spaces for the
   domains of `f` and `g`. This is similar to the sigma-algebra approach to
   independence. See `lintegral_mul_eq_lintegral_mul_lintegral_of_independent_fn` for
   a more common variant of the product of independent variables. -/
lemma lintegral_mul_eq_lintegral_mul_lintegral_of_independent_measurable_space
  {α : Type*} {Mf : measurable_space α} {Mg : measurable_space α} [M : measurable_space α]
  {μ : measure α} (hMf : Mf ≤ M) (hMg : Mg ≤ M)
  (h_ind : indep Mf Mg μ)
  (f g : α → ℝ≥0∞) (h_meas_f : @measurable α ℝ≥0∞ Mf _ f)
  (h_meas_g : @measurable α ℝ≥0∞ Mg _ g):
  ∫⁻ a, (f * g) a ∂μ = (∫⁻ a, f a ∂μ) * (∫⁻ a, g a ∂μ) :=
begin
  revert g,
  have h_meas_Mg : ∀ ⦃f : α → ℝ≥0∞⦄, (@measurable α ℝ≥0∞ Mg _ f) → (measurable f),
  { intros f' h_meas_f', apply measurable.mono h_meas_f' hMg (le_refl _) },
  have h_measM_f := measurable.mono h_meas_f hMf (le_refl _),
  apply measurable.ennreal_induction,
  { intros c s h_s,
    apply lintegral_mul_indicator_eq_lintegral_mul_lintegral_indicator 
       hMf _ (hMg _ h_s) _ h_meas_f,
    apply probability_theory.indep_sets_of_indep_sets_of_le_right h_ind,
    rw singleton_subset_iff, apply h_s },
  { intros f' g h_univ h_measMg_f' h_measMg_g h_ind_f' h_ind_g',
    have h_measM_f' := h_meas_Mg h_measMg_f',
    have h_measM_g := h_meas_Mg h_measMg_g,
    have h_add : (f' + g) = (λ a, (f' a + g a)) := rfl,
    have h8 : (λ a, (f * λ a', (f' a' + g a')) a ) = (λ a, (f a * f' a) + (f a * g a)),
    { ext1 a, simp [left_distrib] },
    have h9 : (λ a, (f * f') a) = (λ a, f a * f' a),
    { ext1 a, refl },
    have h10 : (λ a, (f * g) a) = (λ a, f a * g a),
    { ext1 a, refl },
    rw [h_add, lintegral_add h_measM_f' h_measM_g, h8,
        lintegral_add (measurable.ennreal_mul h_measM_f h_measM_f')
          (measurable.ennreal_mul h_measM_f h_measM_g),
        left_distrib, ← h9, h_ind_f', ← h10, h_ind_g'] },
  { intros f' h_meas_f' h_mono_f' h_ind_f',
    have h_measM_f' := (λ n, h_meas_Mg (h_meas_f' n)),
    have h_mul : (λ (a : α), (f * λ (x : α), ⨆ (n : ℕ), f' n x) a) =
      (λ (a : α), ⨆ (n : ℕ), (λ (x:α), (f x * f' n x)) a),
    { ext1 a, simp only [pi.mul_apply], rw ennreal.mul_supr },
    have h_mul2 : (λ (n:ℕ), ∫⁻ (x : α), f x * f' n x ∂μ) =
        (λ n, (∫⁻ x, f x ∂μ) * ∫⁻ x, f' n x ∂μ),
    { ext1 n, rw ← h_ind_f' n, refl },
    rw [h_mul, lintegral_supr,
        lintegral_supr h_measM_f' h_mono_f', ennreal.mul_supr, h_mul2],
    { apply (λ (n : ℕ), measurable.ennreal_mul h_measM_f (h_measM_f' n)) }, 
    { apply (λ (n : ℕ) (m : ℕ) (h_le : n ≤ m) a, ennreal.mul_le_mul (le_refl _)
      (h_mono_f' h_le a)) } }
end

/-- This proves that if `f` and `g` are independent random variables,
   then `E[f * g] = E[f] * E[g]`. Note that this will only apply to probability
   measures, because `μ (f ⁻¹' univ) * μ (g ⁻¹' univ) = μ ((f ⁻¹' univ) ∩ (g ⁻¹' univ)))`
   implies μ univ * μ univ = μ univ, i.e. μ univ = 1. -/
lemma lintegral_mul_eq_lintegral_mul_lintegral_of_indep_fun {α : Type*} [M : measurable_space α]
  (μ : measure α) (f g : α → ℝ≥0∞) (h_meas_f : measurable f) (h_meas_g : measurable g)
  (h_indep_fun : indep_fun (borel ennreal) (borel ennreal) f g μ):
  ∫⁻ (a : α), (f * g) a ∂μ = (∫⁻ (a : α), f a ∂μ) * (∫⁻ (a : α), g a ∂μ) :=
begin
  apply lintegral_mul_eq_lintegral_mul_lintegral_of_independent_measurable_space
    (measurable_iff_comap_le.1 h_meas_f) (measurable_iff_comap_le.1 h_meas_g),
  apply h_indep_fun,
  repeat { apply measurable.of_comap_le (le_refl _) },
end

end measure_theory