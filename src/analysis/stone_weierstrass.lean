import algebra.algebra.subalgebra
import topology.algebra.continuous_functions
import topology.algebra.polynomial
import topology.bounded_continuous_function
import topology.algebra.affine

noncomputable theory

open continuous_map

variables {X : Type*} {Y : Type*}
/-- A set of functions "separates points"
if for each pair of points there is a function taking different values on them. -/
def separates_points (A : set (X → Y)) : Prop :=
∀ x y : X, x ≠ y → ∃ f ∈ A, (f x : Y) ≠ f y

variables [topological_space X]
variables {R : Type*} [comm_ring R] [topological_space R] [topological_ring R]

abbreviation subalgebra.separates_points (A : subalgebra R C(X, R)) : Prop :=
separates_points ((λ f : C(X, R), (f : X → R)) '' (A : set C(X, R)))

variables [compact_space X]

theorem abs_mem_subalgebra_closure (A : subalgebra ℝ C(X, ℝ)) (f : A) :
  (f : C(X, ℝ)).abs ∈ A.topological_closure :=
begin
  -- rewrite `f.abs` as `abs ∘ f`,
  -- then use that `abs` is in the closure of polynomials on `[-M, M]`,
  -- where `∥f∥ ≤ M`.
  sorry
end

theorem inf_mem_subalgebra_closure (A : subalgebra ℝ C(X, ℝ)) (f g : A) :
  (f : C(X, ℝ)) ⊓ (g : C(X, ℝ)) ∈ A.topological_closure :=
begin
  rw inf_eq,
  refine A.topological_closure.smul_mem
    (A.topological_closure.sub_mem
      (A.topological_closure.add_mem (A.subalgebra_topological_closure f.property)
          (A.subalgebra_topological_closure g.property)) _) _,
  exact_mod_cast abs_mem_subalgebra_closure A _,
end

theorem sup_mem_subalgebra_closure (A : subalgebra ℝ C(X, ℝ)) (f g : A) :
  (f : C(X, ℝ)) ⊔ (g : C(X, ℝ)) ∈ A.topological_closure :=
begin
  rw sup_eq,
  refine A.topological_closure.smul_mem
    (A.topological_closure.add_mem
      (A.topological_closure.add_mem (A.subalgebra_topological_closure f.property)
          (A.subalgebra_topological_closure g.property)) _) _,
  exact_mod_cast abs_mem_subalgebra_closure A _,
end

theorem sublattice_closure_eq_top
  (A : set C(X, ℝ)) (inf_mem : ∀ f g ∈ A, f ⊓ g ∈ A) (sup_mem : ∀ f g ∈ A, f ⊔ g ∈ A)
  (h : separates_points ((λ f : C(X, ℝ), (f : X → ℝ)) '' A)) :
  closure A = ⊤ :=
sorry



variables [t2_space X]

/--
The Stone-Weierstrass approximation theorem,
that a subalgebra `A` of `C(X, ℝ)`, where `X` is a compact Hausdorff space,
is dense if and only if it separates points.
-/
theorem continuous_map.subalgebra_separates_points_iff_topological_closure_eq_top
  (A : subalgebra ℝ C(X, ℝ)) :
  A.topological_closure = ⊤ ↔ A.separates_points :=
sorry

/--
The algebra map from `polynomial R` to continuous functions `C(X, R)`, for any subset `X` of `R`.
-/
@[simps]
def polynomial.as_continuous_map (X : set R) : polynomial R →ₐ[R] C(X, R) :=
{ to_fun := λ p,
  { to_fun := λ x, polynomial.aeval (x : R) p,
    continuous_to_fun :=
    begin
      change continuous ((λ x, polynomial.aeval x p) ∘ (λ x: X, (x : R))),
      continuity,
    end },
  map_zero' := by { ext, simp, },
  map_add' := by { intros, ext, simp, },
  map_one' := by { ext, simp, },
  map_mul' := by { intros, ext, simp, },
  commutes' := by { intros, ext, simp [algebra.algebra_map_eq_smul_one], }, }

-- TODO: when is this injective? When `X` is infinite and `R = ℝ`, at least.

/--
The subalgebra of polynomial functions in `C(X, R)`, for `X` a subset of some topological ring `R`.
-/
def polynomial_functions (X : set R) : subalgebra R C(X, R) :=
(⊤ : subalgebra R (polynomial R)).map (polynomial.as_continuous_map X)

@[simp]
lemma polynomial_functions_coe (X : set R) :
  (polynomial_functions X : set C(X, R)) = set.range (polynomial.as_continuous_map X) :=
by { ext, simp [polynomial_functions], }

-- if `f : R → R` is an affine equivalence, then pulling back along `f`
-- induces an normed algebra isomorphism between `polynomial_functions X` and
-- `polynomial_functions (f ⁻¹' X)`, intertwining the pullback along `f` of `C(R, R)` to itself.

lemma polynomial_functions_separates_points (X : set R) :
  (polynomial_functions X).separates_points :=
λ x y h,
begin
  -- We use `polynomial.X`, then clean up.
  refine ⟨_, ⟨⟨_, ⟨⟨polynomial.X, ⟨algebra.mem_top, rfl⟩⟩, rfl⟩⟩, _⟩⟩,
  dsimp, simp only [polynomial.eval_X],
  exact (λ h', h (subtype.ext h')),
end

abbreviation I := (set.Icc 0 1 : set ℝ)

open filter
open_locale topological_space

def bernstein_approximation (n : ℕ) (f : C(I, ℝ)) : C(I, ℝ) := sorry
theorem bernstein_approximation_uniform (f : C(I, ℝ)) :
  tendsto (λ n : ℕ, bernstein_approximation n f) at_top (𝓝 f) := sorry

/--
The special case of the Weierstrass approximation theorem for the interval `[0,1]`.
We do this first, because the Bernstein polynomials are specifically adapted to this interval.
-/
theorem polynomial_functions_closure_eq_top' :
  (polynomial_functions I).topological_closure = ⊤ :=
begin
  apply eq_top_iff.mpr,
  rintros f -,
  simp only [subalgebra.topological_closure_coe, polynomial_functions_coe],
  refine filter.frequently.mem_closure _,
  refine filter.tendsto.frequently (bernstein_approximation_uniform f) _,
  apply frequently_of_forall,
  intro n,
  sorry,
end

def pullback {X Y : Type*} [topological_space X] [topological_space Y] (f : C(X, Y)) :
  C(Y, ℝ) →ₐ[ℝ] C(X, ℝ) :=
{ to_fun := λ g, g.comp f,
  map_zero' := by { ext, simp, },
  map_add' := λ g₁ g₂, by { ext, simp, },
  map_one' := by { ext, simp, },
  map_mul' := λ g₁ g₂, by { ext, simp, },
  commutes' := λ r, by { ext, simp, }, }

lemma pullback_continuous
  {X Y : Type*} [topological_space X] [compact_space X] [topological_space Y] [compact_space Y]
  (f : C(X, Y)) :
  continuous (pullback f) :=
begin
  change continuous (λ g : C(Y, ℝ), g.comp f),
  refine metric.continuous_iff.mpr _,
  intros g ε ε_pos,
  refine ⟨ε, ε_pos, λ g' h, _⟩,
  erw bounded_continuous_function.dist_lt ε_pos at h ⊢,
  { exact λ x, h (f x), },
  { assumption, },
  { assumption, },
end

def affine_interval_map (a b : ℝ) : C(set.Icc (0 : ℝ) (1 : ℝ), set.Icc a b) :=
begin
  let f₁ : ℝ →ᵃ[ℝ] ℝ := affine_map.line_map a b,
  let f₂ : set.Icc (0 : ℝ) 1 → set.Icc a b :=
    λ x, ⟨f₁ x, begin rcases x with ⟨x, zero_le, le_one⟩, simp, fsplit, sorry, sorry, end⟩,
  have c : continuous f₂ :=
  begin
    apply continuous_subtype_mk,
    change continuous (f₁ ∘ subtype.val),
    continuity,
  end,
  exact ⟨f₂, c⟩,
end


/--
The Weierstrass approximation theorem:
polynomials functions on `[a, b] ⊆ ℝ` are dense in `C([a,b],ℝ)`

(While we could deduce this as an application of the Stone-Weierstrass theorem,
our proof of that relies on the fact that `abs` is in the closure of polynomials on `[-M, M]`,
so we may as well get this done first.)
-/
theorem polynomial_functions_closure_eq_top (a b : ℝ) :
  (polynomial_functions (set.Icc a b)).topological_closure = ⊤ :=
begin
  let T : ℝ → ℝ := λ x, (b - a) * x + a,
  let W : C(set.Icc a b, ℝ) →ₐ[ℝ] C(I, ℝ) := pullback (affine_interval_map a b),
  have p := polynomial_functions_closure_eq_top',
  apply_fun (λ s, s.comap' W) at p,
  simp only [algebra.comap_top] at p,
  -- X.topological_closure.comap' F = (X.comap' F).topological_closure if F is continuous
  -- (polynomial_functions a b).comap' (pullback (affine_interval_map a b)) = (polynomial_functions 0 1)
  sorry
end
