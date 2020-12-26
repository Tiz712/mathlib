/-
Copyright (c) 2020 Alena Gusakov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alena Gusakov, Kyle Miller
-/
import data.fintype.basic
import data.sym2
import combinatorics.simple_graph.basic
import combinatorics.simple_graph.coloring
import combinatorics.simple_graph.subgraph
import combinatorics.simple_graph.degree_sum
import data.fin
import data.set.finite
/-!
# Matchings


## Main definitions

* a `matching` on a simple graph is a subset of its edge set such that
   no two edges share an endpoint.

* a `perfect_matching` on a simple graph is a matching in which every
   vertex belongs to an edge.

TODO:
  - Lemma stating that the existence of a perfect matching on `G` implies that
    the cardinality of `V` is even (assuming it's finite)
  - Hall's Marriage Theorem
  - Tutte's Theorem
  - consider coercions instead of type definition for `matching`:
    https://github.com/leanprover-community/mathlib/pull/5156#discussion_r532935457
  - consider expressing `matching_verts` as union:
    https://github.com/leanprover-community/mathlib/pull/5156#discussion_r532906131

TODO: Tutte and Hall require a definition of subgraphs.
-/
open finset
open fintype
universe u

namespace simple_graph
variables {V : Type u} (G : simple_graph V)

/--
A matching on `G` is a subset of its edges such that no two edges share a vertex.
-/
structure matching :=
(edges : set (sym2 V))
(sub_edges : edges ⊆ G.edge_set)
(disjoint : ∀ (x y ∈ edges) (v : V), v ∈ x → v ∈ y → x = y)

/-- The empty matching of a graph. -/
def matching.empty : G.matching :=
⟨∅, set.empty_subset _, λ _ _ hx, false.elim (set.not_mem_empty _ hx)⟩

instance : inhabited (matching G) :=
⟨matching.empty G⟩

namespace matching
variables {G}

/-- Check whether a given matching matches everything in the first set to something in the second.
This is that the matching can be regarded as a function with domain `V₀` and codomain `V₁`. -/
structure matches_to (M : G.matching) (V₀ V₁ : set V) : Prop :=
(dom : ∀ (v₀ ∈ V₀), ∃ (e ∈ M.edges), v₀ ∈ e)
(cod : ∀ (v₀ ∈ V₀) (v₁ : V), ⟦(v₀, v₁)⟧ ∈ M.edges → v₁ ∈ V₁)

/--
`M.support` is the set of vertices of `G` that are
contained in some edge of the matching `M`
-/
def support (M : G.matching) : set V :=
{v : V | ∃ x, x ∈ M.edges ∧ v ∈ x}

@[simp] lemma mem_support (M : G.matching) (v : V) :
  v ∈ M.support ↔ ∃ x, x ∈ M.edges ∧ v ∈ x :=
iff.rfl

@[simp] lemma empty_support : (matching.empty G).support = ∅ :=
by { ext, simp [empty], }

/-- A matching may be regarded as a subgraph whose vertex set is `M.support` and whose edge set is
`M.edges`. -/
@[simps]
def to_subgraph (M : G.matching) : subgraph G :=
{ V' := M.support,
  adj := λ v w, ⟦(v, w)⟧ ∈ M.edges,
  adj_sub := λ v w h, by { have h' := M.sub_edges h, rwa mem_edge_set at h' },
  edge_vert := λ v w h, by { use ⟦(v, w)⟧, simp [h] },
  sym := λ v w h, by { rw sym2.eq_swap, exact h } }

/--
A perfect matching `M` on graph `G` is a matching such that
  every vertex is contained in an edge of `M`.
-/
def is_perfect (M : G.matching) : Prop :=
M.support = set.univ

lemma is_perfect_iff (M : G.matching) :
  M.is_perfect ↔ ∀ (v : V), ∃ e, e ∈ M.edges ∧ v ∈ e :=
set.eq_univ_iff_forall

/--
A matching defines a partion involutive function on the vertex set.
-/
noncomputable
def opposite (M : G.matching) (v : V) (h : v ∈ M.support) : V :=
(classical.some_spec ((M.mem_support v).mp h)).2.other

lemma opposite_spec (M : G.matching) (v : V) (h : v ∈ M.support) :
  ⟦(v, M.opposite v h)⟧ ∈ M.edges :=
begin
  erw sym2.mem_other_spec, exact (classical.some_spec ((M.mem_support v).mp h)).1,
end

lemma opposite_mem_support (M : G.matching) (v : V) (h : v ∈ M.support) :
  M.opposite v h ∈ M.support :=
⟨⟦(v, M.opposite v h)⟧, M.opposite_spec v h, sym2.mk_has_mem_right _ _⟩

lemma opposite_invol (M : G.matching) (v : V) (h : v ∈ M.support) :
  M.opposite (M.opposite v h) (M.opposite_mem_support v h) = v :=
begin
  have h1 := M.opposite_spec v h,
  have h2 := M.opposite_spec (M.opposite v h) (M.opposite_mem_support v h),
  have hh := M.disjoint _ _ h1 h2 (M.opposite v h) (sym2.mk_has_mem_right _ _) (sym2.mk_has_mem _ _),
  rw sym2.eq_swap at hh, rw sym2.congr_right at hh,
  exact hh.symm,
end

@[simp]
lemma opposite_bij (M : G.matching) (v w : V) (hv : v ∈ M.support) (hw : w ∈ M.support) :
  M.opposite v hv = M.opposite w hw ↔ v = w :=
begin
  split,
  { intro h,
    have h1 := M.opposite_spec v hv,
    have h2 := M.opposite_spec w hw,
    rw h at h1,
    have hh := M.disjoint _ _ h1 h2 (M.opposite w hw) (sym2.mk_has_mem_right _ _) (sym2.mk_has_mem_right _ _),
    exact sym2.congr_left.mp hh },
  { rintro rfl, refl },
end

lemma opposite_ne (M : G.matching) (v : V) (h : v ∈ M.support) :
  M.opposite v h ≠ v :=
(G.edge_not_loop (M.sub_edges (M.opposite_spec v h))).symm

/--
Given a set saturated by a matching, get the set of vertices opposite that set.
-/
def opposite_set (M : G.matching) (S : set V) (h : S ⊆ M.support) : set V :=
{v | ∃ (w : V) (wel : w ∈ S), M.opposite w (h wel) = v}

@[simp]
lemma mem_opposite_set (M : G.matching) (S : set V) (h : S ⊆ M.support) (v : V) :
  v ∈ M.opposite_set S h ↔ ∃ (w : V) (wel : w ∈ S), M.opposite w (h wel) = v :=
by refl

lemma opposite_set_subneighbor_set' (M : G.matching) (S : set V) (h : S ⊆ M.support) :
  M.opposite_set S h ⊆ G.neighbor_set_image S :=
begin
  rintros v ⟨w, wel, hw⟩,
  rw mem_neighbor_set_image,
  use [w, wel],
  have hh := M.sub_edges (M.opposite_spec w (h wel)),
  simpa [hw] using hh,
end

lemma mem_iff_mem_opposite_set (M : G.matching)
  (S : set V) (hS : S ⊆ M.support) (v : V) (hv : v ∈ M.support) :
  v ∈ S ↔ M.opposite v hv ∈ M.opposite_set S hS :=
by simp [opposite_set]

lemma opposite_set_saturated (M : G.matching) (S : set V) (h : S ⊆ M.support) :
  (M.opposite_set S h) ⊆ M.support :=
begin
  rintros v ⟨w, H, hv⟩,
  use ⟦(w, v)⟧,
  refine ⟨_, sym2.mk_has_mem_right _ _⟩,
  convert M.opposite_spec w (h H),
  rw hv,
end

noncomputable
def opposite_set_equiv (M : G.matching) (S : set V) (h : S ⊆ M.support) :
  M.opposite_set S h ≃ S :=
{ to_fun := λ vv, ⟨classical.some vv.2, begin
    rcases classical.some_spec vv.2 with ⟨hw, _⟩,
    exact hw
  end⟩,
  inv_fun := λ vv, ⟨M.opposite vv.1 (h vv.2), (M.mem_iff_mem_opposite_set S h _ (h vv.2)).mp vv.2⟩,
  left_inv := λ ⟨v, hv⟩, begin
    rcases classical.some_spec hv with ⟨he, hop⟩,
    simp [hop],
  end,
  right_inv := λ ⟨v, hv⟩, begin
    dsimp only, congr,
    rcases classical.some_spec ((M.mem_iff_mem_opposite_set S h v (h hv)).mp hv) with ⟨w, hw⟩,
    rwa M.opposite_bij at hw,
  end }

noncomputable
instance opposite_set.fintype
  (M : G.matching) {S : set V} [fintype S] (h : S ⊆ M.support) :
  fintype (M.opposite_set S h) :=
fintype.of_equiv _ ((M.opposite_set_equiv S h).symm)

lemma opposites_card_eq (M : G.matching) {S : set V} [fintype S] (h : S ⊆ M.support) :
  card (M.opposite_set S h) = card S :=
fintype.card_congr (M.opposite_set_equiv S h)

lemma opposite_set_support_eq (M : G.matching) :
  (M.opposite_set M.support (set.subset.refl M.support)) = M.support :=
begin
  apply set.subset.antisymm,
  { apply M.opposite_set_saturated, },
  { rintros v ⟨e, he, hv⟩,
    have hs : v ∈ M.support := ⟨e, he, hv⟩,
    exact ⟨M.opposite v hs, M.opposite_mem_support v hs, M.opposite_invol v hs⟩, },
end

lemma matching_neighbor_set (M : G.matching) (v : V) (h : v ∈ M.support) :
  M.to_subgraph.neighbor_set (⟨v, h⟩ : M.support) = {M.opposite v h} :=
begin
  ext w,
  simp only [to_subgraph_adj, set.mem_singleton_iff, subgraph.mem_neighbor_set, subtype.coe_mk],
  split,
  { intro h',
    have key := M.disjoint _ _ h' (M.opposite_spec v h) v,
    simp only [forall_prop_of_true, sym2.mem_iff, true_or, eq_self_iff_true] at key,
    rwa sym2.congr_right at key, },
  { rintro rfl, exact M.opposite_spec v h, }
end

noncomputable
instance matching_neighbor_set_fintype (M : G.matching) (v : V) (h : v ∈ M.support) :
  fintype (M.to_subgraph.neighbor_set (⟨v, h⟩ : M.support)) :=
by { rw matching_neighbor_set M v h, apply_instance, }

lemma matching_degree_eq_one (M : G.matching) (v : V) (h : v ∈ M.support) :
  M.to_subgraph.degree (⟨v, h⟩ : M.support) = 1 :=
begin
  dunfold subgraph.degree,
  rw fintype.card_congr (equiv.set.of_eq (matching_neighbor_set M v h)),
  rw set.card_singleton,
end

/-noncomputable
def support_opposite (M : G.matching) : M.support → M.support :=
λ vv, ⟨M.opposite vv.1 (vv.2 ∈ M.support),
begin
  have h := (M.mem_iff_mem_opposite_set M.support M.saturates_support _ (M.saturates_support vv.2)).mp vv.2,
  rwa M.opposite_set_support_eq at h,
end⟩

lemma support_opposite_invol (M : G.matching) : function.involutive M.support_opposite :=
by { rintros ⟨v, hv⟩, dunfold support_opposite, simp only [subtype.mk_eq_mk, M.opposite_invol] }

lemma support_opposite_ne (M : G.matching) (v : M.support) :
  M.support_opposite v ≠ v :=
by { rcases v with ⟨v, hv⟩, simp [support_opposite, opposite_ne] }-/

/- lemma card_even_if_fixedpoint_free_invol {α : Type*} [fintype α] [decidable_eq α] (f : α → α)
  (hi : function.involutive f) (hn : ∀ x, x ≠ f x) : even (fintype.card α) :=
begin
  let G : simple_graph α :=
  { adj := λ x y, f x = y,
    sym := begin rintros x y rfl, apply hi, end,
    loopless := begin intro x, exact (hn x).symm end, },
  have h : ∀ (v : α), G.degree v = 1,
  { intro v, simp [degree], dunfold neighbor_finset, dunfold neighbor_set, dunfold adj,
simp,
  }
end -/

lemma support_card_even [fintype V] [decidable_eq V] (M : G.matching) : even (card M.support) :=
--card_even_if_fixedpoint_free_invol M.support_opposite (support_opposite_invol M) (λ x, (support_opposite_ne M x).symm)-/
begin
  sorry,
  --have key : ∀ v, odd (M.to_subgraph.coe.degree v),
  --{ rintro ⟨v, h⟩,
  --  rw matching_degree_eq_one M v h,
  --}
  --convert even_card_odd_degree_vertices M.to_subgraph.coe,
end

/-
noncomputable for now...
instance decide_edge_set_is_matching [fintype V] [decidable_eq V] [decidable_rel G.adj] :
  decidable_pred (λ (s : set (sym2 V)), ∃ (M : G.matching), M.edges = s) :=
begin
  intro edges,
  by_cases sub_edges : edges ⊆ G.edge_set,
  by_cases disjoint : ∀ (x y ∈ edges) (v : V), v ∈ x → v ∈ y → x = y,
  apply decidable.is_true,
  use ⟨edges, sub_edges, disjoint⟩,
  apply decidable.is_false, dsimp, rintro ⟨M, h⟩, cases M, subst edges, exact disjoint M_disjoint,
  apply decidable.is_false, dsimp, rintro ⟨M, h⟩, cases M, subst edges, exact sub_edges M_sub_edges,
end
-/

noncomputable
instance matching_fintype [fintype V] [decidable_eq V] : fintype G.matching :=
begin
  let S := {s : set (sym2 V) | ∃ (M : G.matching), M.edges = s},
  haveI : fintype S := by apply_instance,
  let eqv : G.matching ≃ S :=
  { to_fun := λ M, ⟨M.edges, by use M⟩,
    inv_fun := λ s, {edges := s.1,
                     sub_edges := begin rcases s with ⟨s,M,h⟩, dsimp only, rw ←h, exact M.sub_edges end,
                     disjoint := begin rcases s with ⟨s,M,h⟩, dsimp only, rw ←h, exact M.disjoint end},
    left_inv := begin intro x, cases x, simp, end,
    right_inv := begin intro x, cases x, simp, end,
  },
  exact fintype.of_equiv _ eqv.symm,
end


end matching

open finset
variables (M : G.matching) [fintype M.support]

section bipartite
variables [fintype V] [decidable_eq V] (f : G.bipartition)

/-lemma not_saturates_iff_exists : ¬M.saturates (f.color_set 0) ↔ ∃ u, u ∈ f.color_set 0 ∧ ¬u ∈ M.support :=
begin
  rw ←not_iff_not, push_neg, rw ←set.subset, refl,
end-/

def matching.disjoint_union (M M' : G.matching) (h : disjoint M.support M'.support) : G.matching :=
{ edges := M.edges ∪ M'.edges,
  sub_edges :=
    begin
      simp [M.sub_edges, M'.sub_edges],
    end,
  disjoint := λ e f he hf v hve hvf,
    begin
      let w := hve.other,
      simp at *,
      wlog : e ∈ M.edges := he using M M',
      have hvM : v ∈ M.support,
      rw matching.mem_support,
      refine ⟨e, he, hve⟩,
      have hwM : w ∈ M.support,
      rw matching.mem_support,
      refine ⟨e, he, sym2.mem_other_mem hve⟩,
      have hfM : f ∉ M'.edges,
      let x := hvf.other,
      have hvM' : v ∉ M'.support,
      apply set.disjoint_left.mp h hvM,
      by_contra hfM',
      apply hvM',
      rw matching.mem_support,
      refine ⟨f, hfM', hvf⟩,
      apply M.disjoint e f he,
      tauto,
      exact hve,
      exact hvf,
    end }

/-def matching.disjoint_union' (M M' : G.matching) (e f : sym2 V) (v : V)
 (h : (e ∈ M.edges ∧ f ∈ M'.edges) ∧ v ∈ e ∩ f → e = f) : G.matching :=
{ edges := M.edges ∪ M'.edges,
  sub_edges :=
    begin
      simp [M.sub_edges, M'.sub_edges],
    end,
  disjoint := λ e f he hf v hve hvf,
    begin
      have : v ∈ M.support ∪ M'.support,
      simp at *,
      cases he with hM hM',
      use e,
      refine ⟨hM, hve⟩,
      right,
      use e,
      refine ⟨hM', hve⟩,
      sorry,
    end }-/
  -- h : (e ∈ M.edges ∧ f ∈ M'.edges) ∧ v ∈ e ∩ f → e = f

/--
`alternating_path b u v` is a path starting at u and ending at v, where the edges alternating between being in M and being outside M.
-/
inductive alternating_path (M : G.matching) : bool → V → V → Type u
| start (u : V) : alternating_path tt u u
| consM {u v w : V} (p : alternating_path tt u v) (h : ⟦(v,w)⟧ ∈ M.edges) : alternating_path ff u w
| consNot {u v w : V} (p : alternating_path ff u v) (h : ⟦(v,w)⟧ ∈ G.edge_set \ M.edges) : alternating_path tt u w

lemma foo (α : Type*) [partial_order α] (f : α → α) (h : ∀ (x : α), x ≤ f x) :
  (∀ x, x < f x) ∨ (∃ x, x = f x) :=
begin
  simp_rw le_iff_eq_or_lt at h,
  rw or_iff_not_imp_left,
  intro ha,
  push_neg at ha,
  cases ha with x hx,
  use x,
  specialize h x,
  tauto,
end

lemma hall_marriage_theorem.hard_step (k : ℕ) (f : G.partial_bipartition)
  (hc : fintype.card (f.color_set 0) = k)
  (h : ∀ (S ⊆ f.color_set 0), card S ≤ card (G.neighbor_set_image S)) :
  ∃ (M : G.matching), M.matches_to (f.color_set 0) (f.color_set 1) :=
begin
  revert f,
  refine nat.strong_induction_on k (λ n ih, _),
  intros f hc h,
  by_cases h' : ∀ (S ⊆ f.color_set 0), S.nonempty → card S + 1 ≤ card (G.neighbor_set_image S),
  { cases n,
    { use matching.empty G,
      split; { intros v₀ H, exact false.elim (card_eq_zero_iff.mp hc ⟨v₀, H⟩), }, },
      have hc' : 0 < card (partial_coloring.color_set f 0),
      { rw hc, exact nat.succ_pos _, },
      rcases classical.choice (card_pos_iff.mp hc') with ⟨v, hv⟩,
      have h' : 0 < card (G.neighbor_set_image {v}),
      { refine nat.lt_of_lt_of_le (nat.succ_pos 0) _,
        convert h {v} (by simp [hv]),
        convert (set.card_singleton _).symm, },
      rcases classical.choice (card_pos_iff.mp h') with ⟨w, hw⟩,
      have diff_subset : f.verts \ {v, w} ⊆ f.verts,
      { intro u,
        simp only [and_imp, set.mem_insert_iff, set.mem_diff, set.mem_singleton_iff],
        intros h1 h2,
        exact h1, },
      let f' := f.restrict (f.verts \ {v, w}) diff_subset,
      rcases ih n (lt_add_one n) f' _ _ with ⟨M, hM⟩,
      let M' : G.matching :=
      { edges := insert ⟦(v, w)⟧ M.edges,
        sub_edges := begin
          intro e, simp only [set.mem_insert_iff],
          rintro (rfl | he),
          { simpa using hw, },
          { exact M.sub_edges he, },
        end,
        disjoint := begin
          intros x y hx hy v vx vy,
          simp at hx hy,
        end
      },
      --have h' := h {v} (by simp [hv]),
      --squeeze_simp at h',
   },
  { push_neg at h',
   },
end

theorem hall_marriage_theorem
  (h2 : card (f.color_set 0) ≤ card (f.color_set 1)) :
  (∃ (M : G.matching), (f.color_set 0) ⊆ M.support) ↔
  (∀ (S ⊆ f.color_set 0),
    card S ≤ card (G.neighbor_set_image S)) :=
begin
  split,
  { rintros ⟨M, hM⟩ S hs,
    have Ssat := set.subset.trans hs hM,
    rw ←M.opposites_card_eq Ssat,
    have Sopp := M.opposites_card_eq Ssat,
    exact set.card_le_of_subset (M.opposite_set_subneighbor_set' S Ssat) },
  { intro hh,
    -- ∀ x, x ≤ f x → (∀ x, x < f x) ∨ (∃ x, x = f x)
    --by_contra hv,

    -- induction on `|f.color_set 0|` using partial colorings
      --
      -- have `partial_coloring.restrict f.to_partial`
    -- base case: `|f.color_set 0| = 0`, i.e. `f.color_set 0 = ∅`
      -- this is trivial

    -- IH: `∀ (S ⊆ f.color_set 0), fintype.card S ≤ fintype.card (G.neighbor_set' S))`
    -- ` → ∃ (M : G.matching), (f.color_set 0) ⊆ M.support`
      -- what i mean by this is `f.color_set 0` when you push `f` through to an induced subgraph
    sorry },
end

/- TO DO:

-


-/

end bipartite

end simple_graph
