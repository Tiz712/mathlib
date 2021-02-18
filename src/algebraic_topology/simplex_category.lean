/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Scott Morrison
-/

import order.category.NonemptyFinLinOrd
import category_theory.skeletal
import data.finset.sort
import tactic.linarith

/-! # The simplex category

We construct a skeletal model of the simplex category, with objects `ℕ` and the
morphism `n ⟶ m` being the monotone maps from `fin (n+1)` to `fin (m+1)`.

We show that this category is equivalent to `NonemptyFinLinOrd`.
-/

universe variables u

open category_theory

/-- The simplex category:
* objects are natural numbers `n : ℕ`
* morphisms from `n` to `m` are monotone functions `fin (n+1) → fin (m+1)`
-/
@[derive inhabited]
def simplex_category := ℕ

namespace simplex_category

instance : small_category simplex_category :=
{ hom := λ n m, preorder_hom (fin (n+1)) (fin (m+1)),
  id := λ m, preorder_hom.id,
  comp := λ _ _ _ f g, preorder_hom.comp g f, }

@[simp] lemma id_apply {n : simplex_category} (i : fin (n+1)) :
  (𝟙 n : fin _ → fin _) i = i := rfl
@[simp] lemma comp_apply {l m n : simplex_category} (f : l ⟶ m) (g : m ⟶ n) (i : fin (l+1)) :
  (f ≫ g) i = g (f i) := rfl

section generators
/-!
## Generating maps for the simplex category

PROJECT: prove that the simplex category is equivalent to
one given by the following generators and relations.
-/

/-- The `i`-th face map from `[n]` to `[n+1]` -/
def δ {n} (i : fin (n+2)) :
  @has_hom.hom simplex_category _ n (n+1 : ℕ) :=
(fin.succ_above i).to_preorder_hom

/-- The `i`-th degeneracy map from `[n+1]` to `[n]` -/
def σ {n} (i : fin (n+1)) :
  @has_hom.hom simplex_category _ (n+1 : ℕ) n :=
{ to_fun := fin.pred_above i,
  monotone' := fin.pred_above_right_monotone i }

/-- The generic case of the first simplicial identity -/
lemma δ_comp_δ {n} {i j : fin (n+2)} (H : i ≤ j) :
  δ i ≫ δ j.succ = δ j ≫ δ i.cast_succ :=
begin
  ext k,
  dsimp [δ, fin.succ_above],
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  rcases k with ⟨k, _⟩,
  split_ifs; { simp at *; linarith },
end

/-- The special case of the first simplicial identity -/
lemma δ_comp_δ_self {n} {i : fin (n+2)} : δ i ≫ δ i.cast_succ = δ i ≫ δ i.succ :=
begin
  ext j,
  dsimp [δ, fin.succ_above],
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  split_ifs; { simp at *; linarith },
end

/-- The second simplicial identity -/
lemma δ_comp_σ_of_le {n} {i : fin (n+2)} {j : fin (n+1)} (H : i ≤ j.cast_succ) :
  δ i.cast_succ ≫ σ j.succ = σ j ≫ δ i :=
begin
  ext k,
  dsimp [δ, σ, fin.succ_above, fin.pred_above],
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  rcases k with ⟨k, _⟩,
  simp only [subtype.mk_le_mk, fin.cast_succ_mk] at H,
  simp with push_cast, -- `simp?` doesn't work here
  split_ifs,
  -- Hope for the best from `linarith`:
  all_goals { simp at *, try { linarith }, },
  -- Two of the goals need special handling:
  { replace h_3 := nat.le_of_pred_lt h_3, change k ≤ i at h_3, linarith, },
  { exact (nat.succ_pred_eq_of_pos (lt_of_le_of_lt (zero_le _) h_1)).symm, },
end

/-- The first part of the third simplicial identity -/
lemma δ_comp_σ_self {n} {i : fin (n+1)} :
  δ i.cast_succ ≫ σ i = 𝟙 _ :=
begin
  ext j,
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  dsimp [δ, σ, fin.succ_above, fin.pred_above],
  simp with push_cast,
  split_ifs; { simp at *; linarith, },
end

/-- The second part of the third simplicial identity -/
lemma δ_comp_σ_succ {n} {i : fin (n+1)} :
  δ i.succ ≫ σ i = 𝟙 _ :=
begin
  ext j,
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  dsimp [δ, σ, fin.succ_above, fin.pred_above],
  simp with push_cast,
  split_ifs; { simp at *; linarith, },
end

/-- The fourth simplicial identity -/
lemma δ_comp_σ_of_gt {n} {i : fin (n+2)} {j : fin (n+1)} (H : j.cast_succ < i) :
  δ i.succ ≫ σ j.cast_succ = σ j ≫ δ i :=
begin
  ext k,
  dsimp [δ, σ, fin.succ_above, fin.pred_above],
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  rcases k with ⟨k, _⟩,
  simp at H,
  -- rw apply_dite fin.cast_succ,
  simp [apply_dite fin.cast_succ] with push_cast, -- `simp?` doesn't work here
  split_ifs,
  -- Hope for the best from `linarith`:
  any_goals { simp at *, try { linarith }, },
  -- Four of the goals need special handling:
  { simp at h_1,
    exact lt_irrefl (k - 1) (lt_of_lt_of_le
     (nat.pred_lt (ne_of_lt (lt_of_le_of_lt (zero_le _) h_1)).symm)
     (le_trans (nat.le_of_lt_succ h) h_2)) },
  { simp at h_1, linarith, },
  { exfalso, exact lt_irrefl _ (lt_of_le_of_lt (nat.le_pred_of_lt (nat.lt_of_succ_le h)) h_3), },
  { exact (nat.succ_pred_eq_of_pos (lt_of_le_of_lt (zero_le _) h_2)).symm, },
end

local attribute [simp] fin.pred_mk

/-- The fifth simplicial identity -/
lemma σ_comp_σ {n} {i j : fin (n+1)} (H : i ≤ j) :
  σ i.cast_succ ≫ σ j = σ j.succ ≫ σ i :=
begin
  ext k,
  dsimp [σ, fin.pred_above],
  rcases i with ⟨i, _⟩,
  rcases j with ⟨j, _⟩,
  rcases k with ⟨k, _⟩,
  simp at H,
  simp with push_cast,
  split_ifs,
  -- Hope for the best from `linarith`:
  any_goals { simp at *, try { linarith }, },
  { exact false.elim
    (lt_irrefl (k - 1)
      (lt_of_lt_of_le (nat.pred_lt (id (ne_of_lt (lt_of_le_of_lt (zero_le i) h)).symm))
        (le_trans h_2 (nat.succ_le_of_lt h_1)))) },
  { exact false.elim
    (lt_irrefl j (lt_of_lt_of_le (nat.pred_lt_pred (nat.succ_ne_zero j) h_2) h_1)) },
end

end generators

section skeleton

lemma skeletal : skeletal simplex_category :=
λ X Y I,
begin
  rcases I with ⟨I⟩,
  suffices : fintype.card (fin (X+1)) = fintype.card (fin (Y+1)),
  { simpa, },
  { apply fintype.card_congr,
    refine ⟨I.hom, I.inv, _, _⟩,
    intro x, exact congr_fun (congr_arg (preorder_hom.to_fun) I.hom_inv_id : _) x,
    intro y, exact congr_fun (congr_arg (preorder_hom.to_fun) I.inv_hom_id : _) y, }
end

/-- The functor that exhibits `simplex_category` as skeleton
of `NonemptyFinLinOrd` -/
def skeletal_functor :
  simplex_category ⥤ NonemptyFinLinOrd.{u} :=
{ obj := λ n, NonemptyFinLinOrd.of $ ulift (fin (n+1)),
  map := λ m n f, ⟨λ i, ⟨f i.down⟩, λ ⟨i⟩ ⟨j⟩ h, show f i ≤ f j, from f.monotone h⟩, }

namespace skeletal_functor

instance : full skeletal_functor.{u} :=
{ preimage := λ m n f, ⟨λ i, (f ⟨i⟩).down, λ i j h, f.monotone h⟩,
  witness' := by { intros m n f, dsimp at *, ext1 ⟨i⟩, ext1, refl } }

instance : faithful skeletal_functor.{u} :=
{ map_injective' := λ m n f g h,
  begin
    ext1 i, apply equiv.ulift.symm.injective,
    show skeletal_functor.map f ⟨i⟩ = skeletal_functor.map g ⟨i⟩,
    rw h,
  end }

instance : ess_surj skeletal_functor.{u} :=
{ mem_ess_image := λ X, ⟨(fintype.card X - 1 : ℕ), ⟨begin
    have aux : fintype.card X = fintype.card X - 1 + 1,
    { exact (nat.succ_pred_eq_of_pos $ fintype.card_pos_iff.mpr ⟨⊥⟩).symm, },
    let f := mono_equiv_of_fin X aux,
    have hf := (finset.univ.order_emb_of_fin aux).strict_mono,
    refine
    { hom := ⟨λ i, f i.down, _⟩,
      inv := ⟨λ i, ⟨f.symm i⟩, _⟩,
      hom_inv_id' := _,
      inv_hom_id' := _ },
    { rintro ⟨i⟩ ⟨j⟩ h, show f i ≤ f j, exact hf.monotone h, },
    { intros i j h, show f.symm i ≤ f.symm j, rw ← hf.le_iff_le,
      show f (f.symm i) ≤ f (f.symm j), simpa only [order_iso.apply_symm_apply], },
    { ext1 ⟨i⟩, ext1, exact f.symm_apply_apply i },
    { ext1 i, exact f.apply_symm_apply i },
  end⟩⟩,}

noncomputable instance is_equivalence : is_equivalence skeletal_functor.{u} :=
equivalence.equivalence_of_fully_faithfully_ess_surj skeletal_functor

end skeletal_functor

/-- The equivalence that exhibits `simplex_category` as skeleton
of `NonemptyFinLinOrd` -/
noncomputable def skeletal_equivalence :
  simplex_category ≌ NonemptyFinLinOrd.{u} :=
functor.as_equivalence skeletal_functor.{u}

end skeleton

/-- `simplex_category` is a skeleton of `NonemptyFinLinOrd`. -/
noncomputable
def is_skeleton_of : is_skeleton_of NonemptyFinLinOrd.{u} simplex_category skeletal_functor.{u} :=
{ skel := skeletal,
  eqv := is_equivalence.of_equivalence skeletal_equivalence }

end simplex_category
