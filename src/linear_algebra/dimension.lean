/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Johannes Hölzl, Sander Dahmen
-/
import linear_algebra.basis
import linear_algebra.std_basis
import set_theory.cardinal_ordinal

/-!
# Dimension of modules and vector spaces

## Main definitions

* The dimension of a vector space is defined as `vector_space.dim : cardinal`.

## Main statements

* `mk_eq_mk_of_basis`: the dimension theorem, any two bases of the same vector space have the same
  cardinality.
* `dim_quotient_add_dim`: if V₁ is a submodule of V, then dim (V/V₁) + dim V₁ = dim V.
* `dim_range_add_dim_ker`: the rank-nullity theorem.

## Implementation notes

Many theorems in this file are not universe-generic when they relate dimensions
in different universes. They should be as general as they can be without
inserting `lift`s. The types `V`, `V'`, ... all live in different universes,
and `V₁`, `V₂`, ... all live in the same universe.
-/

noncomputable theory

universes u v v' v'' u₁' w w'

variables {K : Type u} {V V₁ V₂ V₃ : Type v} {V' V'₁ : Type v'} {V'' : Type v''}
variables {ι : Type w} {ι' : Type w'} {η : Type u₁'} {φ : η → Type*}

open_locale classical big_operators

section vector_space
variables [field K] [add_comm_group V] [vector_space K V] [add_comm_group V₁] [vector_space K V₁]
include K
open submodule function set

variables (K V)

/-- the dimension of a vector space, defined as a term of type `cardinal` -/
def vector_space.dim : cardinal :=
cardinal.min
  (nonempty_subtype.2 (@exists_is_basis K V _ _ _))
  (λ b, cardinal.mk b.1)
variables {K V}

open vector_space

section
theorem is_basis.le_span {v : ι → V} {J : set V} (hv : is_basis K v)
   (hJ : span K J = ⊤) : cardinal.mk (range v) ≤ cardinal.mk J :=
begin
  cases le_or_lt cardinal.omega (cardinal.mk J) with oJ oJ,
  { have := cardinal.mk_range_eq_of_injective (linear_independent.injective hv.1),
    let S : J → set ι := λ j, ↑(is_basis.repr hv j).support,
    let S' : J → set V := λ j, v '' S j,
    have hs : range v ⊆ ⋃ j, S' j,
    { intros b hb,
      rcases mem_range.1 hb with ⟨i, hi⟩,
      have : span K J ≤ comap hv.repr (finsupp.supported K K (⋃ j, S j)) :=
        span_le.2 (λ j hj x hx, ⟨_, ⟨⟨j, hj⟩, rfl⟩, hx⟩),
      rw hJ at this,
      replace : hv.repr (v i) ∈ (finsupp.supported K K (⋃ j, S j)) := this trivial,
      rw [hv.repr_eq_single, finsupp.mem_supported,
        finsupp.support_single_ne_zero one_ne_zero] at this,
      { subst b,
        rcases mem_Union.1 (this (finset.mem_singleton_self _)) with ⟨j, hj⟩,
        exact mem_Union.2 ⟨j, (mem_image _ _ _).2 ⟨i, hj, rfl⟩⟩ },
      { apply_instance } },
    refine le_of_not_lt (λ IJ, _),
    suffices : cardinal.mk (⋃ j, S' j) < cardinal.mk (range v),
    { exact not_le_of_lt this ⟨set.embedding_of_subset _ _ hs⟩ },
    refine lt_of_le_of_lt (le_trans cardinal.mk_Union_le_sum_mk
      (cardinal.sum_le_sum _ (λ _, cardinal.omega) _)) _,
    { exact λ j, le_of_lt (cardinal.lt_omega_iff_finite.2 $ (finset.finite_to_set _).image _) },
    { rwa [cardinal.sum_const, cardinal.mul_eq_max oJ (le_refl _), max_eq_left oJ] } },
  { rcases exists_finite_card_le_of_finite_of_linear_independent_of_span
      (cardinal.lt_omega_iff_finite.1 oJ) hv.1.to_subtype_range _ with ⟨fI, hi⟩,
    { rwa [← cardinal.nat_cast_le, cardinal.finset_card, set.finite.coe_to_finset,
        cardinal.finset_card, set.finite.coe_to_finset] at hi, },
    { rw hJ, apply set.subset_univ } },
end
end

/-- dimension theorem -/
theorem mk_eq_mk_of_basis {v : ι → V} {v' : ι' → V}
  (hv : is_basis K v) (hv' : is_basis K v') :
  cardinal.lift.{w w'} (cardinal.mk ι) = cardinal.lift.{w' w} (cardinal.mk ι') :=
begin
  rw ←cardinal.lift_inj.{(max w w') v},
  rw [cardinal.lift_lift, cardinal.lift_lift],
  apply le_antisymm,
  { convert cardinal.lift_le.{v (max w w')}.2 (hv.le_span hv'.2),
    { rw cardinal.lift_max.{w v w'},
      apply (cardinal.mk_range_eq_of_injective hv.injective).symm, },
    { rw cardinal.lift_max.{w' v w},
      apply (cardinal.mk_range_eq_of_injective hv'.injective).symm, }, },
  { convert cardinal.lift_le.{v (max w w')}.2 (hv'.le_span hv.2),
    { rw cardinal.lift_max.{w' v w},
      apply (cardinal.mk_range_eq_of_injective hv'.injective).symm, },
    { rw cardinal.lift_max.{w v w'},
      apply (cardinal.mk_range_eq_of_injective hv.injective).symm, }, }
end

theorem mk_eq_mk_of_basis' {ι' : Type w} {v : ι → V} {v' : ι' → V} (hv : is_basis K v)
  (hv' : is_basis K v') :
  cardinal.mk ι = cardinal.mk ι' :=
cardinal.lift_inj.1 $ mk_eq_mk_of_basis hv hv'

theorem is_basis.mk_eq_dim'' {ι : Type v} {v : ι → V} (h : is_basis K v) :
  cardinal.mk ι = dim K V :=
begin
  obtain ⟨v', e : dim K V = _⟩ := cardinal.min_eq _ _,
  rw e,
  rw ← cardinal.mk_range_eq _ h.injective,
  exact mk_eq_mk_of_basis' h.range v'.2
end

theorem is_basis.mk_range_eq_dim {v : ι → V} (h : is_basis K v) :
  cardinal.mk (range v) = dim K V :=
h.range.mk_eq_dim''

theorem is_basis.mk_eq_dim {v : ι → V} (h : is_basis K v) :
  cardinal.lift.{w v} (cardinal.mk ι) = cardinal.lift.{v w} (dim K V) :=
by rw [←h.mk_range_eq_dim, cardinal.mk_range_eq_of_injective h.injective]

theorem {m} is_basis.mk_eq_dim' {v : ι → V} (h : is_basis K v) :
  cardinal.lift.{w (max v m)} (cardinal.mk ι) = cardinal.lift.{v (max w m)} (dim K V) :=
by simpa using h.mk_eq_dim

theorem dim_le {n : ℕ}
  (H : ∀ s : finset V, linear_independent K (λ i : (↑s : set V), (i : V)) → s.card ≤ n) :
  dim K V ≤ n :=
let ⟨b, hb⟩ := exists_is_basis K V in
hb.mk_eq_dim'' ▸ cardinal.card_le_of (λ s, @finset.card_map _ _ ⟨_, subtype.val_injective⟩ s ▸ H _
(by { refine hb.1.mono (λ y h, _),
  rw [finset.mem_coe, finset.mem_map] at h, rcases h with ⟨x, hx, rfl⟩, exact x.2 } ))

variables [add_comm_group V'] [vector_space K V']

/-- Two linearly equivalent vector spaces have the same dimension, a version with different
universes. -/
theorem linear_equiv.lift_dim_eq (f : V ≃ₗ[K] V') :
  cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v' v} (dim K V') :=
let ⟨b, hb⟩ := exists_is_basis K V in
calc cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v v'} (cardinal.mk b) :
  congr_arg _ hb.mk_eq_dim''.symm
... = cardinal.lift.{v' v} (dim K V') : (f.is_basis hb).mk_eq_dim

/-- Two linearly equivalent vector spaces have the same dimension. -/
theorem linear_equiv.dim_eq (f : V ≃ₗ[K] V₁) :
  dim K V = dim K V₁ :=
cardinal.lift_inj.1 f.lift_dim_eq

/-- Two vector spaces are isomorphic if they have the same dimension. -/
theorem nonempty_linear_equiv_of_lift_dim_eq
  (cond : cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v' v} (dim K V')) :
  nonempty (V ≃ₗ[K] V') :=
begin
  obtain ⟨B, h⟩ := exists_is_basis K V,
  obtain ⟨B', h'⟩ := exists_is_basis K V',
  have : cardinal.lift.{v v'} (cardinal.mk B) = cardinal.lift.{v' v} (cardinal.mk B'),
    by rw [h.mk_eq_dim'', cond, h'.mk_eq_dim''],
  exact (cardinal.lift_mk_eq.{v v' 0}.1 this).map (linear_equiv_of_is_basis h h')
end

/-- Two vector spaces are isomorphic if they have the same dimension. -/
theorem nonempty_linear_equiv_of_dim_eq (cond : dim K V = dim K V₁) :
  nonempty (V ≃ₗ[K] V₁) :=
nonempty_linear_equiv_of_lift_dim_eq $ congr_arg _ cond

section

variables (V V' V₁)

/-- Two vector spaces are isomorphic if they have the same dimension. -/
def linear_equiv.of_lift_dim_eq
  (cond : cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v' v} (dim K V')) :
  V ≃ₗ[K] V' :=
classical.choice (nonempty_linear_equiv_of_lift_dim_eq cond)

/-- Two vector spaces are isomorphic if they have the same dimension. -/
def linear_equiv.of_dim_eq (cond : dim K V = dim K V₁) : V ≃ₗ[K] V₁ :=
classical.choice (nonempty_linear_equiv_of_dim_eq cond)

end

/-- Two vector spaces are isomorphic if and only if they have the same dimension. -/
theorem linear_equiv.nonempty_equiv_iff_lift_dim_eq :
  nonempty (V ≃ₗ[K] V') ↔ cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v' v} (dim K V') :=
⟨λ ⟨h⟩, linear_equiv.lift_dim_eq h, λ h, nonempty_linear_equiv_of_lift_dim_eq h⟩

/-- Two vector spaces are isomorphic if and only if they have the same dimension. -/
theorem linear_equiv.nonempty_equiv_iff_dim_eq : nonempty (V ≃ₗ[K] V₁) ↔ dim K V = dim K V₁ :=
⟨λ ⟨h⟩, linear_equiv.dim_eq h, λ h, nonempty_linear_equiv_of_dim_eq h⟩

@[simp] lemma dim_bot : dim K (⊥ : submodule K V) = 0 :=
by letI := classical.dec_eq V;
  rw [← cardinal.lift_inj, ← (is_basis_empty (⊥ : submodule K V) not_nonempty_pempty).mk_eq_dim,
    cardinal.mk_pempty]

@[simp] lemma dim_top : dim K (⊤ : submodule K V) = dim K V :=
linear_equiv.dim_eq (linear_equiv.of_top _ rfl)

lemma dim_of_field (K : Type*) [field K] : dim K K = 1 :=
by rw [←cardinal.lift_inj, ← (@is_basis_singleton_one punit K _ _).mk_eq_dim, cardinal.mk_punit]

lemma dim_span {v : ι → V} (hv : linear_independent K v) :
  dim K ↥(span K (range v)) = cardinal.mk (range v) :=
by rw [←cardinal.lift_inj, ← (is_basis_span hv).mk_eq_dim,
    cardinal.mk_range_eq_of_injective (@linear_independent.injective ι K V v _ _ _ _ hv)]

lemma dim_span_set {s : set V} (hs : linear_independent K (λ x, x : s → V)) :
  dim K ↥(span K s) = cardinal.mk s :=
by { rw [← @set_of_mem_eq _ s, ← subtype.range_coe_subtype], exact dim_span hs }

lemma {m} cardinal_lift_le_dim_of_linear_independent
  {ι : Type w} {v : ι → V} (hv : linear_independent K v) :
  cardinal.lift.{w (max v m)} (cardinal.mk ι) ≤ cardinal.lift.{v (max w m)} (dim K V) :=
begin
  obtain ⟨ι', v', is⟩ := exists_sum_is_basis hv,
  rw [← cardinal.lift_umax, ← cardinal.lift_umax.{v}],
  simpa using le_trans
    (cardinal.lift_mk_le.{w _ (max v m)}.2 ⟨@function.embedding.inl ι ι'⟩)
    (le_of_eq $ is_basis.mk_eq_dim'.{_ _ _ (max w m)} is),
end

lemma cardinal_le_dim_of_linear_independent
  {ι : Type v} {v : ι → V} (hv : linear_independent K v) :
  (cardinal.mk ι) ≤ (dim.{u v} K V) :=
by simpa using cardinal_lift_le_dim_of_linear_independent hv

lemma cardinal_le_dim_of_linear_independent'
  {s : set V} (hs : linear_independent K (λ x, x : s → V)) :
  cardinal.mk s ≤ dim K V :=
begin
  -- extend s to a basis
  obtain ⟨b, ss, h⟩ := exists_subset_is_basis hs,
  rw [←h.mk_range_eq_dim, subtype.range_coe],
  apply cardinal.mk_le_of_injective (inclusion_injective ss),
end

lemma dim_span_le (s : set V) : dim K (span K s) ≤ cardinal.mk s :=
begin
  classical,
  rcases
    exists_linear_independent (linear_independent_empty K V) (set.empty_subset s)
    with ⟨b, hb, _, hsb, hlib⟩,
  have hsab : span K s = span K b,
    from span_eq_of_le _ hsb (span_le.2 (λ x hx, subset_span (hb hx))),
  convert cardinal.mk_le_mk_of_subset hb,
  rw [hsab, dim_span_set hlib]
end

lemma dim_span_of_finset (s : finset V) :
  dim K (span K (↑s : set V)) < cardinal.omega :=
calc dim K (span K (↑s : set V)) ≤ cardinal.mk (↑s : set V) : dim_span_le ↑s
                             ... = s.card : by rw ←cardinal.finset_card
                             ... < cardinal.omega : cardinal.nat_lt_omega _

theorem dim_prod : dim K (V × V₁) = dim K V + dim K V₁ :=
begin
  letI := classical.dec_eq V,
  letI := classical.dec_eq V₁,
  rcases exists_is_basis K V with ⟨b, hb⟩,
  rcases exists_is_basis K V₁ with ⟨c, hc⟩,
  rw [← cardinal.lift_inj,
      ← @is_basis.mk_eq_dim K (V × V₁) _ _ _ _ _ (is_basis_inl_union_inr hb hc),
      cardinal.lift_add, cardinal.lift_mk,
      ← hb.mk_eq_dim, ← hc.mk_eq_dim,
      cardinal.lift_mk, cardinal.lift_mk,
      cardinal.add_def (ulift b) (ulift c)],
  exact cardinal.lift_inj.1 (cardinal.lift_mk_eq.2
      ⟨equiv.ulift.trans (equiv.sum_congr (@equiv.ulift b) (@equiv.ulift c)).symm ⟩),
end

theorem dim_quotient_add_dim (p : submodule K V) :
  dim K p.quotient + dim K p = dim K V :=
by classical; exact let ⟨f⟩ := quotient_prod_linear_equiv p in dim_prod.symm.trans f.dim_eq

theorem dim_quotient_le (p : submodule K V) :
  dim K p.quotient ≤ dim K V :=
by { rw ← dim_quotient_add_dim p, exact self_le_add_right _ _ }

/-- rank-nullity theorem -/
theorem dim_range_add_dim_ker (f : V →ₗ[K] V₁) : dim K f.range + dim K f.ker = dim K V :=
begin
  haveI := λ (p : submodule K V), classical.dec_eq p.quotient,
  rw [← f.quot_ker_equiv_range.dim_eq, dim_quotient_add_dim]
end

lemma dim_range_le (f : V →ₗ[K] V₁) : dim K f.range ≤ dim K V :=
by { rw ← dim_range_add_dim_ker f, exact self_le_add_right _ _ }

lemma dim_map_le (f : V →ₗ V₁) (p : submodule K V) : dim K (p.map f) ≤ dim K p :=
begin
  have h := dim_range_le (f.comp (submodule.subtype p)),
  rwa [linear_map.range_comp, range_subtype] at h,
end

lemma dim_range_of_surjective (f : V →ₗ[K] V') (h : surjective f) : dim K f.range = dim K V' :=
begin
  refine linear_equiv.dim_eq (linear_equiv.of_bijective (submodule.subtype _) _ _),
  exact linear_map.ker_eq_bot.2 subtype.val_injective,
  rwa [range_subtype, linear_map.range_eq_top]
end

lemma dim_eq_of_surjective (f : V →ₗ[K] V₁) (h : surjective f) : dim K V = dim K V₁ + dim K f.ker :=
by rw [← dim_range_add_dim_ker f, ← dim_range_of_surjective f h]

lemma dim_le_of_surjective (f : V →ₗ[K] V₁) (h : surjective f) : dim K V₁ ≤ dim K V :=
by { rw [dim_eq_of_surjective f h], refine self_le_add_right _ _ }

lemma dim_eq_of_injective (f : V →ₗ[K] V₁) (h : injective f) : dim K V = dim K f.range :=
by rw [← dim_range_add_dim_ker f, linear_map.ker_eq_bot.2 h]; simp [dim_bot]

lemma dim_submodule_le (s : submodule K V) : dim K s ≤ dim K V :=
by { rw ← dim_quotient_add_dim s, exact self_le_add_left _ _ }

lemma dim_le_of_injective (f : V →ₗ[K] V₁) (h : injective f) :
  dim K V ≤ dim K V₁ :=
by { rw [dim_eq_of_injective f h], exact dim_submodule_le _ }

lemma dim_le_of_submodule (s t : submodule K V) (h : s ≤ t) : dim K s ≤ dim K t :=
dim_le_of_injective (of_le h) $ assume ⟨x, hx⟩ ⟨y, hy⟩ eq,
  subtype.eq $ show x = y, from subtype.ext_iff_val.1 eq

lemma linear_independent_le_dim
  {v : ι → V} (hv : linear_independent K v) :
  cardinal.lift.{w v} (cardinal.mk ι) ≤ cardinal.lift.{v w} (dim K V) :=
calc
  cardinal.lift.{w v} (cardinal.mk ι) = cardinal.lift.{v w} (cardinal.mk (set.range v)) :
     (cardinal.mk_range_eq_of_injective (linear_independent.injective hv)).symm
  ... = cardinal.lift.{v w} (dim K (submodule.span K (set.range v))) : by rw (dim_span hv).symm
  ... ≤ cardinal.lift.{v w} (dim K V) : cardinal.lift_le.2 (dim_submodule_le (submodule.span K _))

theorem {u₁} linear_independent_le_dim' {v : ι → V} (hs : linear_independent K v) :
  ((cardinal.mk ι).lift : cardinal.{(max w v u₁)}) ≤
    ((vector_space.dim K V).lift : cardinal.{(max v w u₁)}) :=
cardinal.mk_range_eq_lift hs.injective ▸ dim_span hs ▸ cardinal.lift_le.2 (dim_submodule_le _)

section
variables [add_comm_group V₂] [vector_space K V₂]
variables [add_comm_group V₃] [vector_space K V₃]
open linear_map

/-- This is mostly an auxiliary lemma for `dim_sup_add_dim_inf_eq`. -/
lemma dim_add_dim_split
  (db : V₂ →ₗ[K] V) (eb : V₃ →ₗ[K] V) (cd : V₁ →ₗ[K] V₂) (ce : V₁ →ₗ[K] V₃)
  (hde : ⊤ ≤ db.range ⊔ eb.range)
  (hgd : ker cd = ⊥)
  (eq : db.comp cd = eb.comp ce)
  (eq₂ : ∀d e, db d = eb e → (∃c, cd c = d ∧ ce c = e)) :
  dim K V + dim K V₁ = dim K V₂ + dim K V₃ :=
have hf : surjective (coprod db eb),
begin
  refine (range_eq_top.1 $ top_unique $ _),
  rwa [← map_top, ← prod_top, map_coprod_prod]
end,
begin
  conv {to_rhs, rw [← dim_prod, dim_eq_of_surjective _ hf] },
  congr' 1,
  apply linear_equiv.dim_eq,
  refine linear_equiv.of_bijective _ _ _,
  { refine cod_restrict _ (prod cd (- ce)) _,
    { assume c,
      simp only [add_eq_zero_iff_eq_neg, prod_apply, mem_ker,
        coprod_apply, neg_neg, map_neg, neg_apply],
      exact linear_map.ext_iff.1 eq c } },
  { rw [ker_cod_restrict, ker_prod, hgd, bot_inf_eq] },
  { rw [eq_top_iff, range_cod_restrict, ← map_le_iff_le_comap, map_top, range_subtype],
    rintros ⟨d, e⟩,
    have h := eq₂ d (-e),
    simp only [add_eq_zero_iff_eq_neg, prod_apply, mem_ker, mem_coe, prod.mk.inj_iff,
      coprod_apply, map_neg, neg_apply, linear_map.mem_range] at ⊢ h,
    assume hde,
    rcases h hde with ⟨c, h₁, h₂⟩,
    refine ⟨c, h₁, _⟩,
    rw [h₂, _root_.neg_neg] }
end

lemma dim_sup_add_dim_inf_eq (s t : submodule K V) :
  dim K (s ⊔ t : submodule K V) + dim K (s ⊓ t : submodule K V) = dim K s + dim K t :=
dim_add_dim_split (of_le le_sup_left) (of_le le_sup_right) (of_le inf_le_left) (of_le inf_le_right)
  begin
    rw [← map_le_map_iff' (ker_subtype $ s ⊔ t), map_sup, map_top,
      ← linear_map.range_comp, ← linear_map.range_comp, subtype_comp_of_le, subtype_comp_of_le,
      range_subtype, range_subtype, range_subtype],
    exact le_refl _
  end
  (ker_of_le _ _ _)
  begin ext ⟨x, hx⟩, refl end
  begin
    rintros ⟨b₁, hb₁⟩ ⟨b₂, hb₂⟩ eq,
    have : b₁ = b₂ := congr_arg subtype.val eq,
    subst this,
    exact ⟨⟨b₁, hb₁, hb₂⟩, rfl, rfl⟩
  end

lemma dim_add_le_dim_add_dim (s t : submodule K V) :
  dim K (s ⊔ t : submodule K V) ≤ dim K s + dim K t :=
by { rw [← dim_sup_add_dim_inf_eq], exact self_le_add_right _ _ }

end

section fintype
variable [fintype η]
variables [∀i, add_comm_group (φ i)] [∀i, vector_space K (φ i)]

open linear_map

lemma dim_pi : vector_space.dim K (Πi, φ i) = cardinal.sum (λi, vector_space.dim K (φ i)) :=
begin
  choose b hb using assume i, exists_is_basis K (φ i),
  have : is_basis K (λ (ji : Σ j, b j), std_basis K (λ j, φ j) ji.fst ji.snd.val),
    by apply pi.is_basis_std_basis _ hb,
  rw [←cardinal.lift_inj, ← this.mk_eq_dim],
  simp [λ i, (hb i).mk_range_eq_dim.symm, cardinal.sum_mk]
end

lemma dim_fun {V η : Type u} [fintype η] [add_comm_group V] [vector_space K V] :
  vector_space.dim K (η → V) = fintype.card η * vector_space.dim K V :=
by rw [dim_pi, cardinal.sum_const, cardinal.fintype_card]

lemma dim_fun_eq_lift_mul :
  vector_space.dim K (η → V) = (fintype.card η : cardinal.{max u₁' v}) *
    cardinal.lift.{v u₁'} (vector_space.dim K V) :=
by rw [dim_pi, cardinal.sum_const_eq_lift_mul, cardinal.fintype_card, cardinal.lift_nat_cast]

lemma dim_fun' : vector_space.dim K (η → K) = fintype.card η :=
by rw [dim_fun_eq_lift_mul, dim_of_field K, cardinal.lift_one, mul_one, cardinal.nat_cast_inj]

lemma dim_fin_fun (n : ℕ) : dim K (fin n → K) = n :=
by simp [dim_fun']

end fintype

lemma exists_mem_ne_zero_of_ne_bot {s : submodule K V} (h : s ≠ ⊥) : ∃ b : V, b ∈ s ∧ b ≠ 0 :=
begin
  classical,
  by_contradiction hex,
  have : ∀x∈s, (x:V) = 0, { simpa only [not_exists, not_and, not_not, ne.def] using hex },
  exact (h $ bot_unique $ assume s hs, (submodule.mem_bot K).2 $ this s hs)
end

lemma exists_mem_ne_zero_of_dim_pos {s : submodule K V} (h : 0 < vector_space.dim K s) :
  ∃ b : V, b ∈ s ∧ b ≠ 0 :=
exists_mem_ne_zero_of_ne_bot $ assume eq, by rw [eq, dim_bot] at h; exact lt_irrefl _ h

lemma exists_is_basis_fintype (h : dim K V < cardinal.omega) :
  ∃ s : (set V), (is_basis K (subtype.val : s → V)) ∧ nonempty (fintype s) :=
begin
  cases exists_is_basis K V with s hs,
  rw [←cardinal.lift_lt, ← is_basis.mk_eq_dim hs, cardinal.lift_lt,
      cardinal.lt_omega_iff_fintype] at h,
  exact ⟨s, hs, h⟩
end

section rank

/-- `rank f` is the rank of a `linear_map f`, defined as the dimension of `f.range`. -/
def rank (f : V →ₗ[K] V') : cardinal := dim K f.range

lemma rank_le_domain (f : V →ₗ[K] V₁) : rank f ≤ dim K V :=
by { rw [← dim_range_add_dim_ker f], exact self_le_add_right _ _ }

lemma rank_le_range (f : V →ₗ[K] V₁) : rank f ≤ dim K V₁ :=
dim_submodule_le _

lemma rank_add_le (f g : V →ₗ[K] V') : rank (f + g) ≤ rank f + rank g :=
calc rank (f + g) ≤ dim K (f.range ⊔ g.range : submodule K V') :
  begin
    refine dim_le_of_submodule _ _ _,
    exact (linear_map.range_le_iff_comap.2 $ eq_top_iff'.2 $
      assume x, show f x + g x ∈ (f.range ⊔ g.range : submodule K V'), from
        mem_sup.2 ⟨_, mem_image_of_mem _ (mem_univ _), _, mem_image_of_mem _ (mem_univ _), rfl⟩)
  end
  ... ≤ rank f + rank g : dim_add_le_dim_add_dim _ _

@[simp] lemma rank_zero : rank (0 : V →ₗ[K] V') = 0 :=
by rw [rank, linear_map.range_zero, dim_bot]

lemma rank_finset_sum_le {η} (s : finset η) (f : η → V →ₗ[K] V') :
  rank (∑ d in s, f d) ≤ ∑ d in s, rank (f d) :=
@finset.sum_hom_rel _ _ _ _ _ (λa b, rank a ≤ b) f (λ d, rank (f d)) s (le_of_eq rank_zero)
      (λ i g c h, le_trans (rank_add_le _ _) (add_le_add_left h _))

variables [add_comm_group V''] [vector_space K V'']

lemma rank_comp_le1 (g : V →ₗ[K] V') (f : V' →ₗ[K] V'') : rank (f.comp g) ≤ rank f :=
begin
  refine dim_le_of_submodule _ _ _,
  rw [linear_map.range_comp],
  exact image_subset _ (subset_univ _)
end

variables [add_comm_group V'₁] [vector_space K V'₁]

lemma rank_comp_le2 (g : V →ₗ[K] V') (f : V' →ₗ V'₁) : rank (f.comp g) ≤ rank g :=
by rw [rank, rank, linear_map.range_comp]; exact dim_map_le _ _

end rank

lemma dim_zero_iff_forall_zero : vector_space.dim K V = 0 ↔ ∀ x : V, x = 0 :=
begin
  split,
  { intros h x,
    cases exists_is_basis K V with w hw,
    have card_mk_range := hw.mk_range_eq_dim,
    rw [h, cardinal.mk_emptyc_iff, subtype.range_coe] at card_mk_range,
    simpa [card_mk_range] using hw.mem_span x },
  { intro h,
    have : (⊤ : submodule K V) = ⊥,
    { ext x, simp [h x] },
    rw [←dim_top, this, dim_bot] }
end

lemma dim_zero_iff : vector_space.dim K V = 0 ↔ subsingleton V :=
dim_zero_iff_forall_zero.trans (subsingleton_iff_forall_eq 0).symm

lemma is_basis_of_dim_eq_zero {ι : Type*} (h : ¬ nonempty ι)
  (hV : dim K V = 0) : is_basis K (λ x : ι, (0 : V)) :=
begin
  haveI : subsingleton V := dim_zero_iff.1 hV,
  exact is_basis_empty _ h
end

lemma is_basis_of_dim_eq_zero'
  (hV : dim K V = 0) : is_basis K (λ x : fin 0, (0 : V)) :=
is_basis_of_dim_eq_zero (finset.univ_eq_empty.mp rfl) hV

lemma dim_pos_iff_exists_ne_zero : 0 < vector_space.dim K V ↔ ∃ x : V, x ≠ 0 :=
begin
  rw ←not_iff_not,
  simpa using dim_zero_iff_forall_zero
end

lemma dim_pos_iff_nontrivial : 0 < vector_space.dim K V ↔ nontrivial V :=
begin
  rw dim_pos_iff_exists_ne_zero,
  split,
  { rintros ⟨x, h⟩, exact ⟨⟨x, 0, h⟩⟩ },
  { introsI, exact exists_ne 0 }
end

lemma dim_pos [h : nontrivial V] : 0 < vector_space.dim K V :=
dim_pos_iff_nontrivial.2 h

/-- A vector space has dimension at most `1` if and only if there is a
single vector of which all vectors are multiples. -/
lemma dim_le_one_iff : dim K V ≤ 1 ↔ ∃ v₀ : V, ∀ v, ∃ r : K, r • v₀ = v :=
begin
  obtain ⟨b, h⟩ := exists_is_basis K V,
  split,
  { intro hd,
    rw [←is_basis.mk_eq_dim'' h, cardinal.le_one_iff_subsingleton, subsingleton_coe] at hd,
    rcases eq_empty_or_nonempty b with rfl | ⟨⟨v₀, hv₀⟩⟩,
    { use 0,
      have h' : ∀ v : V, v = 0, { simpa [submodule.eq_bot_iff] using h.2.symm },
      intro v,
      simp [h' v] },
    { use v₀,
      have h' : (K ∙ v₀) = ⊤, { simpa [hd.eq_singleton_of_mem hv₀] using h.2 },
      intro v,
      have hv : v ∈ (⊤ : submodule K V) := mem_top,
      rwa [←h', mem_span_singleton] at hv } },
  { rintros ⟨v₀, hv₀⟩,
    have h : (K ∙ v₀) = ⊤,
    { ext, simp [mem_span_singleton, hv₀] },
    rw [←dim_top, ←h],
    convert dim_span_le _,
    simp }
end

/-- A submodule has dimension at most `1` if and only if there is a
single vector in the submodule such that the submodule is contained in
its span. -/
lemma dim_submodule_le_one_iff (s : submodule K V) : dim K s ≤ 1 ↔ ∃ v₀ ∈ s, s ≤ K ∙ v₀ :=
begin
  simp_rw [dim_le_one_iff, le_span_singleton_iff],
  split,
  { rintro ⟨⟨v₀, hv₀⟩, h⟩,
    use [v₀, hv₀],
    intros v hv,
    obtain ⟨r, hr⟩ := h ⟨v, hv⟩,
    use r,
    simp_rw [subtype.ext_iff, coe_smul, coe_mk] at hr,
    exact hr },
  { rintro ⟨v₀, hv₀, h⟩,
    use ⟨v₀, hv₀⟩,
    rintro ⟨v, hv⟩,
    obtain ⟨r, hr⟩ := h v hv,
    use r,
    simp_rw [subtype.ext_iff, coe_smul, coe_mk],
    exact hr }
end

/-- A submodule has dimension at most `1` if and only if there is a
single vector, not necessarily in the submodule, such that the
submodule is contained in its span. -/
lemma dim_submodule_le_one_iff' (s : submodule K V) : dim K s ≤ 1 ↔ ∃ v₀, s ≤ K ∙ v₀ :=
begin
  rw dim_submodule_le_one_iff,
  split,
  { rintros ⟨v₀, hv₀, h⟩,
    exact ⟨v₀, h⟩ },
  { rintros ⟨v₀, h⟩,
    by_cases hw : ∃ w : V, w ∈ s ∧ w ≠ 0,
    { rcases hw with ⟨w, hw, hw0⟩,
      use [w, hw],
      rcases mem_span_singleton.1 (h hw) with ⟨r', rfl⟩,
      have h0 : r' ≠ 0,
      { rintro rfl,
        simpa using hw0 },
      rwa span_singleton_smul_eq _ h0 },
    { push_neg at hw,
      rw ←submodule.eq_bot_iff at hw,
      simp [hw] } }
end

end vector_space

section unconstrained_universes

variables {E : Type v'}
variables [field K] [add_comm_group V] [vector_space K V]
          [add_comm_group E] [vector_space K E]
open vector_space

/-- Version of linear_equiv.dim_eq without universe constraints. -/
theorem linear_equiv.dim_eq_lift (f : V ≃ₗ[K] E) :
  cardinal.lift.{v v'} (dim K V) = cardinal.lift.{v' v} (dim K E) :=
begin
  cases exists_is_basis K V with b hb,
  rw [← cardinal.lift_inj.1 hb.mk_eq_dim, ← (f.is_basis hb).mk_eq_dim, cardinal.lift_mk],
end

end unconstrained_universes
