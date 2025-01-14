(* infotheo: information theory and error-correcting codes in Coq             *)
(* Copyright (C) 2020 infotheo authors, license: LGPL-2.1-or-later            *)
From mathcomp Require Import all_ssreflect ssralg fingroup perm finalg matrix.
From mathcomp Require boolp.
From mathcomp Require Import Rstruct.
Require Import Reals Lra Nsatz.
Require Import ssrR Reals_ext logb ssr_ext ssralg_ext bigop_ext Rbigop.

(******************************************************************************)
(*                         Finite distributions                               *)
(*                                                                            *)
(* This file provides a formalization of finite probability distributions.    *)
(*                                                                            *)
(*         f @^-1 y == preimage of the point y via the function f where the   *)
(*                     type of x is an eqType                                 *)
(*        {fdist A} == the type of distributions over a finType A             *)
(*     fdist_supp d := [set a | d a != 0]                                     *)
(*           fdist1 == point-supported distribution                           *)
(*        fdistbind == of type fdist A -> (A -> fdist B) -> fdist B           *)
(*                     bind of the "probability monad", notation >>=, scope   *)
(*                     fdist_scope (delimiter: fdist)                         *)
(*         fdistmap == map of the "probability monad"                         *)
(*    fdist_uniform == uniform distribution other a finite type               *)
(*            `U C0 == the uniform distribution with support C, where C0 is a *)
(*                     proof that the set C is not empty                      *)
(* fdist_binary H p == where H is a proof of #|A| = 2%N and p is a            *)
(*                     probability: binary distribution over A with bias p    *)
(*        fdistI2 p == binary distributions over 'I_2                         *)
(*      fdistD1 X P == distribution built from X where the entry b has been   *)
(*                     removed (where P is a proof that X b != 1)             *)
(*      fdist_convn == of type {fdist 'I_n} -> ('I_n->{fdist A}) -> {fdist A} *)
(*                     convex combination of n finite distributions           *)
(*       fdist_conv == convex combination of two distributions                *)
(*                     (convex analogue of vector addition)                   *)
(*                     notation: P1 <| p |> P1 where p is a probability       *)
(*       fdist_perm ==                                                        *)
(*  fdistI_perm s d == s-permutation of the distribution d : {fdist 'I_n}     *)
(*        fdist_add == concatenation of two distributions according to a      *)
(*                     given probability p                                    *)
(*                     (convex analogue of the canonical presentation of      *)
(*                     an element of the direct sum of two {fdist _}s)        *)
(*        fdist_del == restriction of the domain of a distribution            *)
(*                     (convex analogue of the projection of a vector         *)
(*                     to a subspace)                                         *)
(* About bivariate (joint) distributions:                                     *)
(*              P`1 == marginal left                                          *)
(*              P`2 == marginal right                                         *)
(*           P `X W == pair of a distribution and a stochastic matrix         *)
(*         P1 `x P2 == product distribution                                   *)
(*                     (convex analogue of the simple tensor of two vectors)  *)
(*         fdistX P == swap the two projections of P : {fdist A * B}          *)
(*           P `^ n == product distribution over a row vector (fdist_rV)      *)
(*        wolfowitz == Wolfowitz's counting principle                         *)
(* head_of_fdist_rV == head marginal                                          *)
(* tail_of_fdist_rV == tail marginal                                          *)
(*       fdist_col' == marginal distribution                                  *)
(*        fdist_nth ==                                                        *)
(*       fdist_take ==                                                        *)
(*           fdistA ==                                                        *)
(*         fdistC12 ==                                                        *)
(*          fdistAC ==                                                        *)
(*         fdistC13 ==                                                        *)
(*     fdist_proj13 ==                                                        *)
(*     fdist_proj23 ==                                                        *)
(*       fdist_self ==                                                        *)
(*   fdist_prod_nth ==                                                        *)
(*                                                                            *)
(******************************************************************************)

Reserved Notation "{ 'fdist' T }" (at level 0, format "{ 'fdist'  T }").
Reserved Notation "'`U' C0 " (at level 10, C0 at next level).
Reserved Notation "P `^ n" (at level 5).
Reserved Notation "P `X W" (at level 6).
Reserved Notation "P1 `x P2" (at level 6).
Reserved Notation "x <| p |> y" (format "x  <| p |>  y", at level 49).
Reserved Notation "f @^-1 y" (at level 10).
Declare Scope fdist_scope.
Delimit Scope fdist_scope with fdist.

Set Implicit Arguments.
Unset Strict Implicit.
Import Prenex Implicits.

Local Open Scope R_scope.
Local Open Scope reals_ext_scope.

(* NB: f @^-1: [set y] would require to have finType's *)
Notation "f @^-1 y" := (preim f (pred1 y)) : fdist_scope.
Local Open Scope fdist_scope.

(* TODO: move *)
Definition ex2C (T : Type) (P Q : T -> Prop) : @ex2 T P Q <-> @ex2 T Q P.
Proof. by split; case=> x H0 H1; exists x. Qed.

Lemma bij_swap A B : bijective (@swap A B).
Proof. apply Bijective with swap; by case. Qed.
Arguments bij_swap {A B}.

Lemma swapK A B : (@swap A B) \o swap = @id (B * A).
Proof. by rewrite boolp.funeqE => -[]. Qed.

Module FDist.
Section fdist.
Variable A : finType.
Record t := mk {
  f :> A ->R+ ;
  _ : \sum_(a in A) f a == 1 :> R }.
Lemma ge0 (d : t) a : 0 <= d a.
Proof. by case: d => /= f _; exact/nneg_finfun_ge0. Qed.
Lemma f1 (d : t) : \sum_(a in A) d a = 1 :> R.
Proof. by case: d => f /= /eqP. Qed.
Lemma le1 (d : t) a : d a <= 1.
Proof.
rewrite -(f1 d) (_ : d a = \sum_(a' in A | a' == a) d a').
  apply (@leR_sumRl_support _ _ _ xpredT) => // ?; exact/ge0.
by rewrite big_pred1_eq.
Qed.
Definition make (f : {ffun A -> R}) (H0 : forall a, 0 <= f a)
  (H1 : \sum_(a in A) f a = 1) := @mk (@mkNNFinfun _ f
  (proj1 (@reflect_iff _ _ (forallP_leRP _)) H0)) (introT eqP H1).
End fdist.
Module Exports.
Notation fdist := t.
End Exports.
End FDist.
Export FDist.Exports.
Coercion FDist.f : fdist >-> nneg_finfun.
Canonical fdist_subType A := Eval hnf in [subType for @FDist.f A].
Definition fdist_eqMixin A := [eqMixin of fdist A by <:].
Canonical fdist_eqType A := Eval hnf in EqType _ (fdist_eqMixin A).

Global Hint Resolve FDist.ge0 : core.
Global Hint Resolve FDist.le1 : core.

Definition fdist_of (A : finType) := fun phT : phant (Finite.sort A) => fdist A.

Notation "{ 'fdist' T }" := (fdist_of (Phant T)) : fdist_scope.

Lemma fdist_ge0_le1 (A : finType) (d : fdist A) a : 0 <= d a <= 1.
Proof. by []. Qed.

Definition probfdist (A : finType) (d : fdist A) a :=
  Eval hnf in Prob.mk_ (fdist_ge0_le1 d a).

Section fdist_lemmas.

Variable A : finType.
Implicit Types d : fdist A.

Definition is_fdist (f : A -> R) : Prop :=
  (forall a, 0 <= f a) /\ (\sum_(a in A) f a = 1).

Lemma fdist_is_fdist d : is_fdist d.
Proof. by case: d; case => f /= /forallP_leRP H0 /eqP H1. Qed.

Lemma fdist_card_neq0 d : (0 < #| A |)%nat.
Proof.
apply/negPn/negP => abs; apply R1_neq_R0.
rewrite -(FDist.f1 d) (eq_bigl xpred0) ?big_pred0_eq // => a.
apply/negP => aA.
by move/card_gt0P : abs; apply; exists a.
Qed.

Definition fdist_supp d := [set a | d a != 0].

Lemma sum_fdist_supp (f : A -> R) d (P : pred A):
  \sum_(a in A | P a) d a * f a = \sum_(a | P a && (a \in fdist_supp d)) d a * f a.
Proof.
rewrite (bigID (mem (fdist_supp d))) /= addRC big1 ?add0R//.
by move=> i; rewrite inE negbK => /andP[_ /eqP] ->; rewrite mul0R.
Qed.

Lemma fdist_supp_neq0 (d : fdist A) : fdist_supp d != set0.
Proof.
apply/eqP => H; move: (FDist.f1 d).
rewrite -[LHS]mulR1 big_distrl sum_fdist_supp H big1 //=.
  by move/esym; exact: R1_neq_R0.
by move=> i; rewrite inE.
Qed.

Lemma fdist_supp_mem (d : fdist A) : {i | i \in fdist_supp d}.
Proof.
by case: (set_0Vmem (fdist_supp d)) (fdist_supp_neq0 d) => // ->; rewrite eqxx.
Qed.

Lemma fdist_ind (P : fdist A -> Type) :
  (forall n : nat, (forall X, #|fdist_supp X| = n -> P X) ->
    forall X b, #|fdist_supp X| = n.+1 -> X b != 0 -> P X) ->
  forall X, P X.
Proof.
move=> H1 d.
move: {-2}(#|fdist_supp d|) (erefl (#|fdist_supp d|)) => n; move: n d.
elim=> [d /esym /card0_eq Hd0|n IH d n13].
  move: (FDist.f1 d).
  rewrite -[X in X = _]mulR1 big_distrl sum_fdist_supp big1 => [|a].
    by move/esym/R1_neq_R0.
  by rewrite Hd0.
have [b Hb] : {b : A | d b != 0}.
  suff : {x | x \in fdist_supp d} by case => a; rewrite inE => ?; exists a.
  by apply/sigW/set0Pn; rewrite -cards_eq0 -n13.
by refine (H1 n _ _ _ _ Hb) => // d' A2; apply IH.
Qed.

Lemma fdist_gt0 d a : (d a != 0) <-> (0 < d a).
Proof.
split => H; [|by move/gtR_eqF : H].
by rewrite ltR_neqAle; split => //; exact/nesym/eqP.
Qed.

Lemma fdist_lt1 d a : (d a != 1) <-> (d a < 1).
Proof.
split=> H; first by rewrite ltR_neqAle; split => //; exact/eqP.
exact/ltR_eqF.
Qed.

Lemma fdist_ext d d' : (forall x, d x = d' x) -> d = d'.
Proof. by move=> ?; exact/val_inj/val_inj/ffunP. Qed.

End fdist_lemmas.

Section fdist1.
Variables (A : finType) (a : A).
Let f := [ffun b => INR (b == a)%bool].

Let f0 b : 0 <= f b. Proof. by rewrite ffunE; exact: leR0n. Qed.

Let f1 : \sum_(b in A) f b = 1.
Proof.
rewrite (bigD1 a) //= {1}/f ffunE eqxx /= (eq_bigr (fun=> 0)); last first.
  by move=> b ba; rewrite /f ffunE (negbTE ba).
by rewrite big1_eq // addR0.
Qed.

Definition fdist1 : fdist A := locked (FDist.make f0 f1).

Lemma fdist1E a0 : fdist1 a0 = INR (a0 == a)%bool.
Proof. by rewrite /fdist1; unlock; rewrite ffunE. Qed.

Lemma supp_fdist1 : fdist_supp fdist1 = [set a] :> {set A}.
Proof.
apply/setP => a0; rewrite !inE; case/boolP : (_ == _ :> A) => [/eqP ->|a0a].
by rewrite fdist1E eqxx; apply/negbT => /=; apply/eqP; rewrite INR_eq0.
by apply/negbTE; rewrite negbK fdist1E (negbTE a0a).
Qed.

End fdist1.

Section fdist1_prop.
Variable A : finType.

Lemma fdist1P (d : {fdist A}) a : reflect (forall i, i != a -> d i = 0) (d a == 1).
Proof.
apply: (iffP idP) => [/eqP H b ?|H].
- move: (FDist.f1 d); rewrite (bigD1 a) //= H => /esym/eqP.
  rewrite addRC -subR_eq' subRR.
  by move/eqP/esym/psumR_eq0P => -> // c ca; exact/fdist_ge0.
- move: (FDist.f1 d); rewrite (bigD1 a) //= => /esym.
  by rewrite -subR_eq => <-; rewrite big1 // subR0.
Qed.

Lemma fdist1E1 (d' : fdist A) a : (d' a == 1 :> R) = (d' == fdist1 a :> {fdist A}).
Proof.
apply/idP/idP => [Pa1|/eqP ->]; last by rewrite fdist1E eqxx.
apply/eqP/fdist_ext => a0; rewrite fdist1E.
case/boolP : (a0 == a :> A) => Ha.
by rewrite (eqP Ha); exact/eqP.
by move/fdist1P : Pa1 => ->.
Qed.

Lemma fdist1I1 (d : {fdist 'I_1}) : d = fdist1 ord0.
Proof.
apply/fdist_ext => /= i; rewrite fdist1E (ord1 i) eqxx.
by move: (FDist.f1 d); rewrite big_ord_recl big_ord0 addR0.
Qed.

Lemma fdist1xx (a : A) : fdist1 a a = 1.
Proof. by rewrite fdist1E eqxx. Qed.

Lemma fdist10 (a a0 : A) : a0 != a -> fdist1 a a0 = 0.
Proof. by move=> a0a; rewrite fdist1E (negbTE a0a). Qed.

End fdist1_prop.

Section fdistbind.
Variables (A B : finType) (p : fdist A) (g : A -> fdist B).

Let f := [ffun b => \sum_(a in A) p a * (g a) b].

Let f0 b : 0 <= f b.
Proof. rewrite /f ffunE; apply sumR_ge0 => a _; exact: mulR_ge0. Qed.

Let f1 : \sum_(b in B) f b = 1.
Proof.
rewrite /f.
under eq_bigr do rewrite ffunE.
rewrite exchange_big /= -[RHS](FDist.f1 p); apply eq_bigr => a _.
by rewrite -big_distrr /= FDist.f1 mulR1.
Qed.

Definition fdistbind : fdist B := locked (FDist.make f0 f1).

Lemma fdistbindE x : fdistbind x = \sum_(a in A) p a * (g a) x.
Proof. by rewrite /fdistbind; unlock; rewrite ffunE. Qed.

End fdistbind.

Reserved Notation "m >>= f" (at level 49).
Notation "m >>= f" := (fdistbind m f) : fdist_scope.

Lemma fdist1bind (A B : finType) (a : A) (f : A -> fdist B) :
  fdist1 a >>= f = f a.
Proof.
apply/fdist_ext => b; rewrite fdistbindE /= (bigD1 a) //= fdist1xx mul1R.
rewrite (eq_bigr (fun=> 0)) ?big_const ?iter_addR ?mulR0 ?addR0 // => c ca.
by rewrite fdist10// mul0R.
Qed.

Lemma fdistbind1 A (p : fdist A) : p >>= @fdist1 A = p.
Proof.
apply/fdist_ext => /= a; rewrite fdistbindE /= (bigD1 a) //= fdist1xx mulR1.
rewrite (eq_bigr (fun=> 0)) ?big_const ?iter_addR ?mulR0 /= ?addR0 //.
by move=> b ba; rewrite fdist10 ?mulR0// eq_sym.
Qed.

Lemma fdistbindA A B C (m : fdist A) (f : A -> fdist B) (g : B -> fdist C) :
  (m >>= f) >>= g = m >>= (fun x => f x >>= g).
Proof.
apply/fdist_ext => c; rewrite !fdistbindE /=.
rewrite (eq_bigr (fun a => \sum_(a0 in A) m a0 * f a0 a * g a c)); last first.
  by move=> b _; rewrite fdistbindE big_distrl.
rewrite exchange_big /=; apply eq_bigr => a _.
by rewrite fdistbindE big_distrr /=; apply eq_bigr => b _; rewrite mulRA.
Qed.

Section fdistmap.
Variables (A B : finType) (g : A -> B) (p : fdist A).

Definition fdistmap : {fdist B} := p >>= (fun a => fdist1 (g a)).

Lemma fdistmapE (b : B) : fdistmap b = \sum_(a in A | a \in g @^-1 b) p a.
Proof.
rewrite /fdistmap fdistbindE [in RHS]big_mkcond /=; apply eq_bigr => a _.
case: ifPn => [|]; first by rewrite inE => /eqP->; rewrite fdist1xx mulR1.
by rewrite !inE => gab; rewrite fdist10 ?mulR0// eq_sym.
Qed.
End fdistmap.

Section fdistmap_prop.
Variables (A B C : finType).

Lemma fdistmap_id P : fdistmap (@id A) P = P. Proof.
by rewrite /fdistmap fdistbind1. Qed.

Lemma fdistmap_comp (g : A -> B) (h : C -> A) P :
  fdistmap g (fdistmap h P) = fdistmap (g \o h) P.
Proof.
rewrite /fdistmap fdistbindA; congr (_ >>= _).
by rewrite boolp.funeqE => x; rewrite fdist1bind.
Qed.

End fdistmap_prop.

Section fdist_uniform.
Variables (A : finType) (n : nat).

Hypothesis domain_not_empty : #|A| = n.+1.
Let f := [ffun a : A => INR 1 / INR #|A|].

Let f0 a : 0 <= f a.
Proof.
by rewrite ffunE; apply/divR_ge0 => //; apply/ltR0n; rewrite domain_not_empty.
Qed.

Let f1 : \sum_(a in A) f a = 1.
Proof.
under eq_bigr do rewrite ffunE.
rewrite -big_distrr /= mul1R big_const iter_addR mulRV //.
by rewrite INR_eq0' domain_not_empty.
Qed.

Definition fdist_uniform : fdist A := locked (FDist.make f0 f1).

Lemma fdist_uniformE a : fdist_uniform a = / INR #|A|.
Proof. by rewrite /fdist_uniform; unlock => /=; rewrite /f div1R ffunE. Qed.

End fdist_uniform.

Section fdist_uniform_prop.

Lemma fdist_uniform_neq0 (C : finType) (domain_non_empty : { m : nat | #| C | = m.+1 }) :
  forall x, fdist_uniform (projT2 domain_non_empty) x != 0.
Proof.
move=> c; rewrite fdist_uniformE invR_neq0' //; apply/eqP.
case: domain_non_empty => x' ->; by rewrite INR_eq0.
Qed.

End fdist_uniform_prop.

Lemma dom_by_uniform A (P : fdist A) n (An1 : #|A| = n.+1) : P `<< fdist_uniform An1.
Proof.
apply/dominatesP => a; rewrite fdist_uniformE => /esym abs; exfalso.
by move: abs; rewrite An1; apply/eqP; rewrite ltR_eqF //; apply/invR_gt0/ltR0n.
Qed.

Section fdist_uniform_supp.
Variables (A : finType) (C : {set A}).
Hypothesis C0 : (0 < #|C|)%nat.

Let f := [ffun a : A => if a \in C then 1 / INR #|C| else 0].

Let f0 a : 0 <= f a.
Proof.
rewrite /f ffunE.
case e : (a \in C); last exact/leRR.
apply divR_ge0; [lra|exact/ltR0n].
Qed.

Lemma f1 : \sum_(a in A) f a = 1.
Proof.
rewrite /f.
have HC' : #|C|%:R != 0 by rewrite INR_eq0' -lt0n.
transitivity (\sum_(a in A) (if a \in C then 1 else 0) / INR #|C|).
apply eq_bigr => a _.
  rewrite ffunE; case aC : (a \in C); by [ | move/eqP in HC'; field].
have HC'' : \sum_(a in A) (if a \in C then 1 else 0) = #|C|%:R.
  by rewrite -big_mkcondr /= big_const iter_addR mulR1.
by rewrite /Rdiv -big_distrl HC'' /= mulRV.
Qed.

Definition fdist_uniform_supp : fdist A := locked (FDist.make f0 f1).

End fdist_uniform_supp.

Notation "'`U' C0 " := (fdist_uniform_supp C0).

Section fdist_uniform_supp_prop.
Variables (A : finType) (C : {set A}) (HC : (0 < #| C |)%nat).

Lemma fdist_uniform_supp_in z : z \in C -> (`U HC) z = 1 / INR #|C|.
Proof. by rewrite /fdist_uniform_supp; unlock; rewrite /= /f ffunE => ->. Qed.

Lemma fdist_uniform_supp_notin z : z \notin C -> (`U HC) z = 0.
Proof.
by rewrite /fdist_uniform_supp; unlock; move/negbTE; rewrite /= /f ffunE => ->.
Qed.

Lemma fdist_uniform_supp_restrict g :
  \sum_(t in A) ((`U HC) t * g t) = \sum_(t in C) ((`U HC) t * g t).
Proof.
rewrite (bigID (fun x => x \in C)) /= addRC big1 ?add0R// => a aC.
by rewrite fdist_uniform_supp_notin // mul0R.
Qed.

Lemma fdist_uniform_supp_distrr g :
  \sum_(t in C) ((`U HC) t * g t) = (/ INR #|C| * \sum_(t in C) g t).
Proof.
rewrite /= big_distrr /=; apply eq_bigr => /= i Hi.
by rewrite fdist_uniform_supp_in // div1R.
Qed.

Lemma fdist_uniform_supp_neq0 z : ((`U HC) z != 0) = (z \in C).
Proof.
case/boolP : (z \in C) => [/fdist_uniform_supp_in ->|/fdist_uniform_supp_notin ->].
  by rewrite div1R; apply/invR_neq0'; rewrite INR_eq0' -lt0n.
by rewrite eqxx.
Qed.

End fdist_uniform_supp_prop.

Section fdist_binary.
Variable A : finType.
Hypothesis HA : #|A| = 2%nat.
Variable p : prob.

Let f (a : A) := [ffun a' => if a' == a then p.~ else p].

Let f0 (a a' : A) : 0 <= f a a'.
Proof. by rewrite /f ffunE; case: ifP. Qed.

Let f1 (a : A) : \sum_(a' in A) f a a' = 1.
Proof.
rewrite Set2sumE /= /f !ffunE; case: ifPn => [/eqP <-|].
  by rewrite eq_sym (negbTE (Set2.a_neq_b HA)) subRK.
by rewrite eq_sym; move/Set2.neq_a_b/eqP => <-; rewrite eqxx subRKC.
Qed.

Definition fdist_binary : A -> fdist A :=
  fun a => locked (FDist.make (f0 a) (f1 a)).

Lemma fdist_binaryE a a' : fdist_binary a a' = if a' == a then 1 - p else p.
Proof. by rewrite /fdist_binary; unlock; rewrite ffunE. Qed.

Lemma sum_fdist_binary_swap a :
  \sum_(a' in A) fdist_binary a a' = \sum_(a' in A) fdist_binary a' a.
Proof. by rewrite 2!Set2sumE /= !fdist_binaryE !(eq_sym a). Qed.

Lemma fdist_binaryxx a : fdist_binary a a = 1 - p.
Proof. by rewrite fdist_binaryE eqxx. Qed.

End fdist_binary.

Section fdist_binary_prop.
Variables (A : finType) (P Q : fdist A).
Hypothesis card_A : #|A| = 2%nat.

Lemma charac_bdist : {r : prob | P = fdist_binary card_A r (Set2.a card_A)}.
Proof.
destruct P as [[pf pf0] pf1].
have /leR2P r01 : 0 <= 1 - pf (Set2.a card_A) <= 1.
  move: (FDist.le1 (FDist.mk pf1) (Set2.a card_A)) => /= H1.
  have {}pf1 : \sum_(a in A) pf a = 1 by rewrite -(eqP pf1); apply eq_bigr.
  move/forallP_leRP : pf0 => /(_ (Set2.a card_A)) => H0.
  split; first lra.
  suff : forall a, a <= 1 -> 0 <= a -> 1 - a <= 1 by apply.
  move=> *; lra.
exists (Prob.mk r01).
apply/fdist_ext => a /=.
rewrite fdist_binaryE; case: ifPn => [/eqP -> /=|Ha/=]; first by rewrite subRB subRR add0R.
by rewrite -(eqP pf1) /= Set2sumE /= addRC addRK; move/Set2.neq_a_b/eqP : Ha => ->.
Qed.

End fdist_binary_prop.

Section fdist_binary_supp.
Variables (A : finType) (d : fdist A).

Hypothesis Hd : #|fdist_supp d| = 2%nat.

Definition fdist_binary_supp0 := enum_val (cast_ord (esym Hd) ord0).

Definition fdist_binary_supp1 := enum_val (cast_ord (esym Hd) (lift ord0 ord0)).

Lemma enum_fdist_binary_supp :
  enum (fdist_supp d) = fdist_binary_supp0 :: fdist_binary_supp1 :: [::].
Proof.
apply (@eq_from_nth _ fdist_binary_supp0); first by rewrite -cardE Hd.
case=> [_ |]; first by rewrite [X in _ = X]/= {2}/fdist_binary_supp0 (enum_val_nth fdist_binary_supp0).
case=> [_ |i]; last by rewrite -cardE Hd.
by rewrite [X in _ = X]/= {1}/fdist_binary_supp1 (enum_val_nth fdist_binary_supp0).
Qed.

Lemma sum_fdist_binary_supp (f : A -> R) :
  \sum_(i in fdist_supp d) f i = f fdist_binary_supp0 + f fdist_binary_supp1.
Proof.
transitivity (\sum_(i <- enum (fdist_supp d)) f i); last first.
  by rewrite enum_fdist_binary_supp 2!big_cons big_nil addR0.
by rewrite big_filter; apply eq_bigl => ?; rewrite !inE.
Qed.

End fdist_binary_supp.

Section fdistD1.
Variables (B : finType) (X : fdist B) (b : B).

Definition f : B -> R := [ffun a => if a == b then 0 else X a / (1 - X b)].

Hypothesis Xb1 : X b != 1.

Let f0 : forall a, 0 <= f a.
Proof.
move=> a; rewrite /f ffunE.
case: ifPn => [_ |ab]; first exact/leRR.
apply mulR_ge0 => //; exact/invR_ge0/subR_gt0/fdist_lt1.
Qed.

Let f1 : \sum_(a in B) f a = 1.
Proof.
rewrite (bigD1 b) //= {1}/f ffunE eqxx add0R.
rewrite (eq_bigr (fun c => X c / (1 - X b))); last first.
  by move=> ? cb; rewrite /f ffunE (negbTE cb).
rewrite -big_distrl /=.
move: (FDist.f1 X); rewrite (bigD1 b) //=.
move=> /esym; rewrite addRC -subR_eq => H.
have ?: 1 - X b != 0 by rewrite subR_eq0' eq_sym.
rewrite -(@eqR_mul2r (1 - X b)); last exact/eqP.
by rewrite mul1R -mulRA mulVR ?mulR1 // H.
Qed.

Definition fdistD1 := locked (FDist.make f0 f1).

Lemma fdistD1E a : fdistD1 a = if a == b then 0 else X a / (1 - X b).
Proof. by rewrite /fdistD1; unlock; rewrite ffunE. Qed.

End fdistD1.

Section fdistD1_prop.
Variables (B : finType) (X : fdist B) (b : B).

Hypothesis Xb1 : X b != 1.

Lemma card_supp_fdistD1 (Xb0 : X b != 0) :
  #|fdist_supp (fdistD1 Xb1)| = #|fdist_supp X|.-1.
Proof.
rewrite /fdist_supp (cardsD1 b [set a | X a != 0]) !inE Xb0 add1n /=.
apply eq_card => i; rewrite !inE fdistD1E.
case: ifPn => //= ib; first by rewrite eqxx.
apply/idP/idP; first by apply: contra => /eqP ->; rewrite div0R.
apply: contra; rewrite /Rdiv mulR_eq0' => /orP[//|H].
exfalso.
move/negPn/negP : H; apply.
by apply/invR_neq0'; rewrite subR_eq0' eq_sym.
Qed.

Lemma fdistD1_eq0 a (Xa0 : X a != 0) : ((fdistD1 Xb1 a == 0) = (b == a))%bool.
Proof.
rewrite fdistD1E; case: ifPn => [/eqP ->|ab]; first by rewrite !eqxx.
apply/idP/idP => [|]; last by rewrite eq_sym (negbTE ab).
rewrite mulR_eq0' => /orP[]; first by rewrite (negbTE Xa0).
by move/invR_eq0'; rewrite subR_eq0' eq_sym (negbTE Xb1).
Qed.

Lemma fdistD1_0 a : X a = 0 -> fdistD1 Xb1 a = 0.
Proof. by move=> Xa0; rewrite fdistD1E Xa0 div0R; case: ifP. Qed.

End fdistD1_prop.

(* TODO: move? *)
(* about_distributions_of_ordinals.*)

Lemma fdistI0_False (d : {fdist 'I_O}) : False.
Proof. move: (fdist_card_neq0 d); by rewrite card_ord. Qed.

Section fdistI2.
Variable p : prob.

Definition fdistI2: {fdist 'I_2} := fdist_binary (card_ord 2) p (lift ord0 ord0).

Lemma fdistI2E a : fdistI2 a = if a == ord0 then Prob.p p else p.~.
Proof.
rewrite /fdistI2 fdist_binaryE; case: ifPn => [/eqP ->|].
by rewrite eq_sym (negbTE (neq_lift _ _)).
by case: ifPn => //; move: a => -[[//|[|]//]].
Qed.

End fdistI2.

Section fdistI2_prop.
Variable p : prob.

Lemma fdistI21 : fdistI2 1%:pr = fdist1 ord0.
Proof.
apply/fdist_ext => /= i; rewrite fdistI2E fdist1E; case: ifPn => //= _.
exact: onem1.
Qed.

Lemma fdistI20 : fdistI2 0%:pr = fdist1 (Ordinal (erefl (1 < 2)%nat)).
Proof.
apply/fdist_ext => /= i; rewrite fdistI2E fdist1E; case: ifPn => [/eqP ->//|].
by case: i => -[//|] [|//] i12 _ /=; rewrite onem0.
Qed.

End fdistI2_prop.

Section fdist_add.
Variables (n m : nat) (d1 : {fdist 'I_n}) (d2 : {fdist 'I_m}) (p : prob).

Let f := [ffun i : 'I_(n + m) =>
  let si := fintype.split i in
  match si with inl a => (p * d1 a) | inr a => p.~ * d2 a end].

Let f0 i : 0 <= f i.
Proof. by rewrite /f ffunE; case: splitP => a _; exact: mulR_ge0. Qed.

Let f1 : \sum_(i < n + m) f i = 1.
Proof.
rewrite -(onemKC p) -{1}(mulR1 p) -(mulR1 p.~).
rewrite -{1}(FDist.f1 d1) -(FDist.f1 d2) big_split_ord /=; congr (_ + _).
- rewrite big_distrr /f /=; apply eq_bigr => i _; rewrite ffunE.
  case: splitP => [j Hj|k /= Hi].
  + by congr (_ * d1 _); apply/val_inj => /=; rewrite -Hj.
  + by move: (ltn_ord i); rewrite Hi -ltn_subRL subnn ltn0.
- rewrite big_distrr /f /=; apply eq_bigr => i _; rewrite ffunE.
  case: splitP => [j /= Hi|k /= /eqP].
  + by move: (ltn_ord j); rewrite -Hi -ltn_subRL subnn ltn0.
  + by rewrite eqn_add2l => /eqP ik; congr (_ * d2 _); exact/val_inj.
Qed.

Definition fdist_add : {fdist 'I_(n + m)} := locked (FDist.make f0 f1).

Lemma fdist_addE i : fdist_add i =
  match fintype.split i with inl a => p * d1 a | inr a => p.~ * d2 a end.
Proof. by rewrite /fdist_add; unlock; rewrite ffunE. Qed.

End fdist_add.

Section fdist_del.
Variables (n : nat) (P : {fdist 'I_n.+1}) (j : 'I_n.+1) (Pj_neq1 : P j != 1).

Let D : {fdist 'I_n.+1} := fdistD1 Pj_neq1.

Let h (i : 'I_n) := if (i < j)%nat then widen_ord (leqnSn _) i else lift ord0 i.

Let f0 i : 0 <= [ffun x => (D \o h) x] i.
Proof. by rewrite /h ffunE /=; case: ifPn. Qed.

Let f1 : \sum_(i < n) [ffun x => (D \o h) x] i = 1.
Proof.
rewrite -(FDist.f1 D) /= (bigID (fun i : 'I_n.+1 => (i < j)%nat)) /=.
rewrite (bigID (fun i : 'I_n => (i < j)%nat)) /=; congr (_ + _).
  rewrite (@big_ord_narrow_cond _ _ _ j n.+1 xpredT); first by rewrite ltnW.
  move=> jn; rewrite (@big_ord_narrow_cond _ _ _ j n xpredT); first by rewrite -ltnS.
  move=> jn'; apply eq_bigr => i _; rewrite ffunE; congr (D _).
  rewrite /h /= ltn_ord; exact/val_inj.
rewrite (bigID (pred1 j)) /= [X in _ = X + _](_ : _ = 0) ?add0R; last first.
  rewrite (big_pred1 j).
  by rewrite /D fdistD1E eqxx.
  by move=> /= i; rewrite -leqNgt andbC andb_idr // => /eqP ->.
rewrite [in RHS]big_mkcond big_ord_recl.
set X := (X in _ = addR_monoid _ X).
rewrite /= -leqNgt leqn0 eq_sym andbN add0R.
rewrite big_mkcond; apply eq_bigr => i _.
rewrite -2!leqNgt andbC eq_sym -ltn_neqAle ltnS.
case: ifPn => // ji; by rewrite /h ffunE ltnNge ji.
Qed.

Definition fdist_del : {fdist 'I_n} := locked (FDist.make f0 f1).

Lemma fdist_delE i : fdist_del i = D (h i).
Proof. by rewrite /fdist_del; unlock; rewrite ffunE. Qed.

Definition fdist_del_idx (i : 'I_n) := h i.

End fdist_del.

Section fdist_belast.
Variables (n : nat) (P : {fdist 'I_n.+1}) (Pmax_neq1 : P ord_max != 1).

Let D : {fdist 'I_n.+1} := fdistD1 Pmax_neq1.

Definition fdist_belast : {fdist 'I_n} := locked (fdist_del Pmax_neq1).

Lemma fdist_belastE i : fdist_belast i = D (widen_ord (leqnSn _) i).
Proof. by rewrite /fdist_belast; unlock; rewrite fdist_delE ltn_ord. Qed.

End fdist_belast.

Section fdist_convn.
Variables (A : finType) (n : nat) (e : {fdist 'I_n}) (g : 'I_n -> fdist A).

Let f := [ffun a => \sum_(i < n) e i * g i a].

Let f0 a : 0 <= f a.
Proof. by rewrite ffunE; apply: sumR_ge0 => /= i _; apply mulR_ge0. Qed.

Let f1 : \sum_(a in A) f a = 1.
Proof.
under eq_bigr do rewrite ffunE.
rewrite exchange_big /= -(FDist.f1 e) /=; apply eq_bigr => i _.
by rewrite -big_distrr /= FDist.f1 mulR1.
Qed.

Definition fdist_convn : fdist A := locked (FDist.make f0 f1).

Lemma fdist_convnE a : fdist_convn a = \sum_(i < n) e i * g i a.
Proof. by rewrite /fdist_convn; unlock; rewrite ffunE. Qed.

End fdist_convn.

Section fdist_convn_prop.
Variables (A : finType) (n : nat).

Lemma fdist_convn1 (g : 'I_n -> fdist A) a : fdist_convn (fdist1 a) g = g a.
Proof.
apply/fdist_ext => a0; rewrite fdist_convnE (bigD1 a) //= fdist1xx mul1R.
by rewrite big1 ?addR0 // => i ia; rewrite fdist10// mul0R.
Qed.

Lemma fdist_convn_cst (e : {fdist 'I_n}) (a : {fdist A}) :
  fdist_convn e (fun=> a) = a.
Proof.
by apply/fdist_ext => ?; rewrite fdist_convnE -big_distrl /= FDist.f1 mul1R.
Qed.

End fdist_convn_prop.

Section fdist_conv.
Variables (A : finType) (p : prob) (d1 d2 : fdist A).

Definition fdist_conv : {fdist A} := locked
  (fdist_convn (fdistI2 p) (fun i => if i == ord0 then d1 else d2)).

Lemma fdist_convE a : fdist_conv a = p * d1 a + p.~ * d2 a.
Proof.
rewrite /fdist_conv; unlock => /=.
by rewrite fdist_convnE !big_ord_recl big_ord0 /= addR0 !fdistI2E.
Qed.

End fdist_conv.

Notation "x <| p |> y" := (fdist_conv p x y) : fdist_scope.

Lemma fdist_conv_bind_left_distr (A B : finType) p a b (f : A -> fdist B) :
  (a <| p |> b) >>= f = (a >>= f) <| p |> (b >>= f).
Proof.
apply/fdist_ext => a0 /=; rewrite !(fdistbindE,fdist_convE) /=.
rewrite 2!big_distrr /= -big_split /=; apply/eq_bigr => a1 _.
by rewrite fdist_convE mulRDl !mulRA.
Qed.

Section fdist_perm.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n}) (s : 'S_n).

Definition fdist_perm : {fdist 'rV[A]_n} := fdistmap (col_perm s^-1) P.

Lemma fdist_permE v : fdist_perm v = P (col_perm s v).
Proof.
rewrite fdistmapE /= {1}(_ : v = col_perm s^-1 (col_perm s v)); last first.
  by rewrite -col_permM mulVg col_perm1.
rewrite big_pred1_inj //; exact: col_perm_inj.
Qed.
End fdist_perm.

Section fdistI_perm.
Variables (n : nat) (P : {fdist 'I_n}) (s : 'S_n).

Let f := [ffun i : 'I_n => P (s i)].

Let f0 (i : 'I_n) : 0 <= f i. Proof. by rewrite ffunE. Qed.

Let f1 : \sum_(i < n) f i = 1.
Proof.
transitivity (\sum_(i <- [tuple (s^-1)%g i | i < n]) f i).
  apply/perm_big/tuple_permP; exists s.
  destruct n; first by move: (fdistI0_False P).
  rewrite /index_enum -enumT; apply/(@eq_from_nth _ ord0).
    by rewrite size_map size_tuple -enumT size_enum_ord.
  move=> i; rewrite size_enum_ord => ni /=.
  rewrite (nth_map ord0) ?size_enum_ord //= tnth_map /=.
  apply (@perm_inj _ s); by rewrite permKV /= tnth_ord_tuple.
rewrite -(FDist.f1 P) /= big_map; apply congr_big => //.
  by rewrite /index_enum -enumT.
move=> i _; by rewrite /f ffunE permKV.
Qed.

Definition fdistI_perm : {fdist 'I_n} := locked (FDist.make f0 f1).

Lemma fdistI_permE i : fdistI_perm i = P (s i).
Proof. by rewrite /fdistI_perm; unlock; rewrite ffunE. Qed.

End fdistI_perm.

Section fdistI_perm_prop.

Lemma fdistI_perm1 (n : nat) (P : {fdist 'I_n}) : fdistI_perm P 1%g = P.
Proof. by apply/fdist_ext => /= i; rewrite fdistI_permE perm1. Qed.

Lemma fdistI_permM (n : nat) (P : {fdist 'I_n}) (s s' : 'S_n) :
  fdistI_perm (fdistI_perm P s) s' = fdistI_perm P (s' * s).
Proof. by apply/fdist_ext => /= i; rewrite !fdistI_permE permM. Qed.

Lemma fdistI_tperm (n : nat) (a b : 'I_n) :
  fdistI_perm (fdist1 a) (tperm a b) = fdist1 b.
Proof.
apply/fdist_ext => /= x; rewrite fdistI_permE !fdist1E permE /=.
case: ifPn => [/eqP ->|xa]; first by rewrite eq_sym.
case: ifPn; by [rewrite eqxx | move=> _; rewrite (negbTE xa)].
Qed.

Lemma fdistI_perm_fdist1 (n : nat) (a : 'I_n) (s : 'S_n) :
  fdistI_perm (fdist1 a) s = fdist1 (s^-1 a)%g.
Proof.
apply/fdist_ext => /= i; rewrite fdistI_permE !fdist1E; congr (INR (nat_of_bool _)).
by apply/eqP/eqP => [<-|->]; rewrite ?permK // ?permKV.
Qed.

End fdistI_perm_prop.

Reserved Notation "d `1" (at level 2, left associativity, format "d `1").
Reserved Notation "d `2" (at level 2, left associativity, format "d `2").

Section fdist_fst_snd.
Variables (A B : finType) (P : {fdist A * B}).

Definition fdist_fst : fdist A := fdistmap fst P.

Lemma fdist_fstE a : fdist_fst a = \sum_(i in B) P (a, i).
Proof.
by rewrite fdistmapE /= -(pair_big_fst _ _ (pred1 a)) //= ?big_pred1_eq.
Qed.

Lemma dom_by_fdist_fst a b : fdist_fst a = 0 -> P (a, b) = 0.
Proof. rewrite fdist_fstE => /psumR_eq0P -> // ? _; exact: fdist_ge0. Qed.

Lemma dom_by_fdist_fstN a b : P (a, b) != 0 -> fdist_fst a != 0.
Proof. by apply: contra => /eqP /dom_by_fdist_fst ->. Qed.

Definition fdist_snd : fdist B := fdistmap snd P.

Lemma fdist_sndE b : fdist_snd b = \sum_(i in A) P (i, b).
Proof.
rewrite fdistmapE -(pair_big_snd _ _ (pred1 b)) //=.
by apply eq_bigr => a ?; rewrite big_pred1_eq.
Qed.

Lemma dom_by_fdist_snd a b : fdist_snd b = 0 -> P (a, b) = 0.
Proof. by rewrite fdist_sndE => /psumR_eq0P -> // ? _; exact: fdist_ge0. Qed.

Lemma dom_by_fdist_sndN a b : P (a, b) != 0 -> fdist_snd b != 0.
Proof. by apply: contra => /eqP /dom_by_fdist_snd ->. Qed.

End fdist_fst_snd.

Notation "d `1" := (fdist_fst d) : fdist_scope.
Notation "d `2" := (fdist_snd d) : fdist_scope.

Section fdist_prod.
Variables (A B : finType) (P : fdist A) (W : A -> fdist B).

Let f := [ffun ab => P ab.1 * W ab.1 ab.2].

Let f0 ab : 0 <= f ab. Proof. by rewrite ffunE; apply/mulR_ge0. Qed.

Let f1 : \sum_(ab in {: A * B}) f ab = 1.
Proof.
under eq_bigr do rewrite ffunE.
rewrite -(pair_bigA _ (fun i j => P i * W i j)) /= -(FDist.f1 P).
by apply eq_bigr => a _; rewrite -big_distrr FDist.f1 /= mulR1.
Qed.

Definition fdist_prod := locked (FDist.make f0 f1).

Lemma fdist_prodE ab : fdist_prod ab = P ab.1 * W ab.1 ab.2.
Proof. by rewrite /fdist_prod; unlock; rewrite ffunE. Qed.

Lemma fdist_prod1 : fdist_prod`1 = P.
Proof.
apply/fdist_ext=> a; rewrite fdist_fstE (eq_bigr _ (fun b _ => fdist_prodE (a,b))) /=.
by rewrite -big_distrr FDist.f1 /= mulR1.
Qed.

End fdist_prod.

Notation "P `X W" := (fdist_prod P W) : fdist_scope.

Section fdist_prod_prop.
Variables (A B : finType) (W : A -> fdist B).

Lemma fdist_prod1_conv p (a b : fdist A) :
  ((a <| p |> b) `X W)`1 = (a `X W)`1 <| p |> (b `X W)`1.
Proof. by rewrite !fdist_prod1. Qed.

Lemma fdist_prod2_conv p (a b : fdist A) :
  ((a <| p |> b) `X W)`2 = (a `X W)`2 <| p |> (b `X W)`2.
Proof.
apply/fdist_ext => b0.
rewrite fdist_sndE fdist_convE !fdist_sndE 2!big_distrr /=.
by rewrite -big_split; apply eq_bigr => a0 _; rewrite !fdist_prodE fdist_convE /=; field.
Qed.

End fdist_prod_prop.
Notation "P1 `x P2" := (P1 `X (fun _ => P2)) : fdist_scope.

Section prod_dominates_joint.
Local Open Scope reals_ext_scope.
Variables (A B : finType) (P : {fdist A * B}).

Lemma Prod_dominates_Joint : P `<< P`1 `x P`2.
Proof.
apply/dominatesP => -[a b].
rewrite fdist_prodE /= mulR_eq0 => -[P1a|P2b];
  by [rewrite dom_by_fdist_fst | rewrite dom_by_fdist_snd].
Qed.

End prod_dominates_joint.

Section fdistX.
Variables (A B : finType) (P : {fdist A * B}).

Definition fdistX : {fdist B * A} := fdistmap swap P.

Lemma fdistXE a b : fdistX (b, a) = P (a, b).
Proof.
by rewrite fdistmapE /= -/(swap (a, b)) (big_pred1_inj (bij_inj bij_swap)).
Qed.

Lemma fdistX1 : fdistX`1 = P`2.
Proof. by rewrite /fdist_fst /fdistX fdistmap_comp. Qed.

Lemma fdistX2 : fdistX`2 = P`1.
Proof. by rewrite /fdist_snd /fdistX fdistmap_comp. Qed.

End fdistX.

Section fdistX_prop.
Variables (A B : finType) (P : fdist A) (Q : fdist B) (R S : {fdist A * B}).

Lemma fdistXI : fdistX (fdistX R) = R.
Proof. by rewrite /fdistX fdistmap_comp swapK fdistmap_id. Qed.

Lemma fdistX_prod : fdistX (Q `x P) = P `x Q.
Proof. by apply/fdist_ext => -[a b]; rewrite fdistXE !fdist_prodE mulRC. Qed.

Local Open Scope reals_ext_scope.

Lemma fdistX_dom_by : dominates R S -> dominates (fdistX R) (fdistX S).
Proof.
by move/dominatesP => H; apply/dominatesP => -[b a]; rewrite !fdistXE => /H.
Qed.

End fdistX_prop.

Lemma fdistX_prod2 (A B : finType) (P : fdist A) (W : A -> fdist B) :
  (fdistX (P `X W))`2 = P.
Proof. by rewrite fdistX2 fdist_prod1. Qed.

Section fdist_rV.
Local Open Scope vec_ext_scope.
Variables (A : finType) (P : fdist A) (n : nat).

Let f := [ffun t : 'rV[A]_n => \prod_(i < n) P t ``_ i].

Let f0 t : 0 <= f t.
Proof. by rewrite ffunE; apply prodR_ge0. Qed.

Let f1 : \sum_(t in 'rV_n) f t = 1.
Proof.
pose P' := fun (a : 'I_n) b => P b.
suff : \sum_(g : {ffun 'I_n -> A }) \prod_(i < n) P' i (g i) = 1.
Local Open Scope ring_scope.
  rewrite (reindex_onto (fun j : 'rV[A]_n => finfun (fun x => j ``_ x))
                        (fun i => \row_(j < n) i j)) /=.
Local Close Scope ring_scope.
  - move=> H; rewrite /f -H {H}.
    apply eq_big => t /=.
    + by apply/esym/eqP/rowP => i; rewrite mxE ffunE.
    + move=> _; rewrite ffunE; apply eq_bigr => i _ /=; by rewrite ffunE.
  move=> g _; apply/ffunP => i; by rewrite ffunE mxE.
rewrite -bigA_distr_bigA /= /P'.
rewrite [RHS](_ : _ = \prod_(i < n) 1); last by rewrite big1.
by apply eq_bigr => i _; exact: FDist.f1.
Qed.

Definition fdist_rV : {fdist 'rV[A]_n} := locked (FDist.make f0 f1).

Lemma fdist_rVE t : fdist_rV t = \prod_(i < n) P t ``_ i.
Proof. by rewrite /fdist_rV; unlock; rewrite ffunE. Qed.

End fdist_rV.

Notation "P `^ n" := (fdist_rV P n) : fdist_scope.

Section wolfowitz_counting.

Variables (C : finType) (P : fdist C) (k : nat) (s : {set 'rV[C]_k}).

Lemma wolfowitz a b A B : 0 < A -> 0 < B ->
  a <= \sum_(x in s) P `^ k x <= b ->
  (forall x : 'rV_k, x \in s -> A <= P `^ k x <= B) ->
  a / B <= INR #| s | <= b / A.
Proof.
move=> A0 B0 [Ha Hb] H.
have HB : \sum_(x in s) P `^ _ x <= INR #|s| * B.
  have HB : \sum_(x in s | predT s ) P `^ _ x <= INR #|s| * B.
    apply (@leR_trans (\sum_(x in s | predT s) [fun _ => B] x)).
      by apply leR_sumR_support => /= i iA _; apply H.
    rewrite -big_filter /= big_const_seq /= iter_addR /=.
    apply leR_wpmul2r; first lra.
    apply Req_le.
    have [/= l el [ul ls] [pl sl]] := big_enumP _.
    rewrite count_predT sl; congr (_%:R)%R.
    by apply: eq_card => /= v; rewrite inE andbT.
  by apply/(leR_trans _ HB)/Req_le/eq_bigl => i; rewrite andbC.
have HA : INR #|s| * A <= \sum_(x in s) P `^ _ x.
  have HA : INR #|s| * A <= \sum_(x in s | predT s) P `^ _ x.
    apply (@leR_trans (\sum_(x in s | predT s) [fun _ => A] x)); last first.
      apply leR_sumR_support => i Hi _; by case: (H i Hi).
    rewrite -big_filter /= big_const_seq /= iter_addR /=.
    apply leR_wpmul2r; first lra.
    apply Req_le.
    have [/= l el [ul ls] [pl sl]] := big_enumP _.
    rewrite count_predT sl; congr (_%:R)%R.
    by apply: eq_card => /= v; rewrite inE andbT.
  by apply/(leR_trans HA)/Req_le/eq_bigl => i; rewrite andbC.
split.
- by rewrite leR_pdivr_mulr //; move/leR_trans : Ha; exact.
- by rewrite leR_pdivl_mulr //; exact: (leR_trans HA).
Qed.

End wolfowitz_counting.

Section fdist_prod_of_rV.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}).

Let f (v : 'rV[A]_n.+1) : A * 'rV[A]_n := (v ord0 ord0, rbehead v).

Let inj_f : injective f.
Proof.
move=> a b -[H1 H2]; rewrite -(row_mx_rbehead a) -(row_mx_rbehead b).
by rewrite {}H2; congr (@row_mx _ 1 1 n _ _); apply/rowP => i; rewrite !mxE.
Qed.

Definition fdist_prod_of_rV : {fdist A * 'rV[A]_n} := fdistmap f P.

Lemma fdist_prod_of_rVE a :
  fdist_prod_of_rV a = P (row_mx (\row_(i < 1) a.1) a.2).
Proof.
case: a => x y; rewrite /fdist_prod_of_rV fdistmapE /=.
rewrite (_ : (x, y) = f (row_mx (\row_(i < 1) x) y)); last first.
  by rewrite /f row_mx_row_ord0 rbehead_row_mx.
by rewrite (big_pred1_inj inj_f).
Qed.

Definition head_of_fdist_rV := fdist_prod_of_rV`1.
Definition tail_of_fdist_rV := fdist_prod_of_rV`2.

Let g (v : 'rV[A]_n.+1) : 'rV[A]_n * A := (rbelast v, rlast v).

Let inj_g : injective g.
Proof.
by move=> a b -[H1 H2]; rewrite -(row_mx_rbelast a) -(row_mx_rbelast b) H1 H2.
Qed.

Definition fdist_belast_last_of_rV : {fdist 'rV[A]_n * A} := fdistmap g P.

Lemma fdist_belast_last_of_rVE a : fdist_belast_last_of_rV a =
  P (castmx (erefl, addn1 n) (row_mx a.1 (\row_(i < 1) a.2))).
Proof.
case: a => x y; rewrite /fdist_belast_last_of_rV fdistmapE /=.
rewrite (_ : (x, y) = g (castmx (erefl 1%nat, addn1 n) (row_mx x (\row__ y)))); last first.
  by rewrite /g rbelast_row_mx row_mx_row_ord_max.
by rewrite (big_pred1_inj inj_g).
Qed.

End fdist_prod_of_rV.

Lemma head_of_fdist_rV_belast_last (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+2}) :
  head_of_fdist_rV ((fdist_belast_last_of_rV P)`1) = head_of_fdist_rV P.
Proof.
rewrite /head_of_fdist_rV /fdist_fst /fdist_prod_of_rV /fdist_belast_last_of_rV.
rewrite !fdistmap_comp; congr (fdistmap _ P).
rewrite boolp.funeqE => /= v /=.
rewrite /rbelast mxE; congr (v ord0 _); exact: val_inj.
Qed.

Section fdist_rV_of_prod.
Local Open Scope vec_ext_scope.
Variables (A : finType) (n : nat) (P : {fdist A * 'rV[A]_n}).

Let f (x : A * 'rV[A]_n) : 'rV[A]_n.+1 := row_mx (\row_(_ < 1) x.1) x.2.
Lemma inj_f : injective f.
Proof.
move=> -[x1 x2] -[y1 y2]; rewrite /f /= => H.
move: (H) => /(congr1 (@lsubmx A 1 1 n)); rewrite 2!row_mxKl => /rowP/(_ ord0).
rewrite !mxE => ->; congr (_, _).
by move: H => /(congr1 (@rsubmx A 1 1 n)); rewrite 2!row_mxKr.
Qed.

Definition fdist_rV_of_prod : {fdist 'rV[A]_n.+1} := fdistmap f P.

Lemma fdist_rV_of_prodE a : fdist_rV_of_prod a = P (a ``_ ord0, rbehead a).
Proof.
rewrite /fdist_rV_of_prod fdistmapE /=.
rewrite {1}(_ : a = f (a ``_ ord0, rbehead a)); last first.
  by rewrite /f /= row_mx_rbehead.
by rewrite (big_pred1_inj inj_f).
Qed.

End fdist_rV_of_prod.

Section fdist_rV_prop.
Local Open Scope vec_ext_scope.
Variable A : finType.

Lemma fdist_prod_of_rVK n : cancel (@fdist_rV_of_prod A n) (@fdist_prod_of_rV A n).
Proof.
move=> P; apply/fdist_ext => /= -[a b].
by rewrite fdist_prod_of_rVE /= fdist_rV_of_prodE /= row_mx_row_ord0 rbehead_row_mx.
Qed.

Lemma fdist_rV_of_prodK n : cancel (@fdist_prod_of_rV A n) (@fdist_rV_of_prod A n).
Proof.
move=> P; apply/fdist_ext => v.
by rewrite fdist_rV_of_prodE fdist_prod_of_rVE row_mx_rbehead.
Qed.

Lemma fdist_rV0 (x : 'rV[A]_0) P : P `^ 0 x = 1.
Proof. by rewrite fdist_rVE big_ord0. Qed.

Lemma fdist_rVS n (x : 'rV[A]_n.+1) P :
  P `^ n.+1 x = P (x ``_ ord0) * P `^ n (rbehead x).
Proof.
rewrite 2!fdist_rVE big_ord_recl; congr (_ * _).
by apply eq_bigr => i _; rewrite /rbehead mxE.
Qed.

Lemma fdist_rV1 (a : 'rV[A]_1) P : (P `^ 1) a = P (a ``_ ord0).
Proof. by rewrite fdist_rVS fdist_rV0 mulR1. Qed.

Lemma fdist_prod_of_fdist_rV n (P : fdist A) :
  fdist_prod_of_rV (P `^ n.+1) = P `x P `^ n.
Proof.
apply/fdist_ext => /= -[a b].
rewrite fdist_prod_of_rVE /= fdist_rVS fdist_prodE; congr (P _ * P `^ n _) => /=.
  by rewrite row_mx_row_ord0.
by rewrite rbehead_row_mx.
Qed.

Lemma head_of_fdist_rV_fdist_rV n (P : fdist A) :
  head_of_fdist_rV (P `^ n.+1) = P.
Proof.
apply/fdist_ext => a; rewrite /head_of_fdist_rV fdist_fstE /=.
under eq_bigr.
  move=> v _; rewrite fdist_prod_of_rVE /= fdist_rVS.
  by rewrite row_mx_row_ord0 rbehead_row_mx; over.
by rewrite -big_distrr /= FDist.f1 mulR1.
Qed.

Lemma tail_of_fdist_rV_fdist_rV n (P : fdist A) :
  tail_of_fdist_rV (P `^ n.+1) = P `^ n.
Proof.
apply/fdist_ext => a; rewrite /tail_of_fdist_rV fdist_sndE /=.
under eq_bigr.
  move=> v _; rewrite fdist_prod_of_rVE /= fdist_rVS.
  by rewrite row_mx_row_ord0 rbehead_row_mx; over.
by rewrite -big_distrl /= FDist.f1 mul1R.
Qed.

End fdist_rV_prop.

Section fdist_col'.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}) (i : 'I_n.+1).

Definition fdist_col' : {fdist 'rV[A]_n} := fdistmap (col' i) P.

Lemma fdist_col'E v : fdist_col' v = \sum_(x : 'rV[A]_n.+1 | col' i x == v) P x.
Proof. by rewrite fdistmapE. Qed.

End fdist_col'.

Section fdist_col'_prop.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}).

Lemma tail_of_fdist_rV_fdist_col' : tail_of_fdist_rV P = fdist_col' P ord0.
Proof.
by rewrite /fdist_col' /tail_of_fdist_rV /fdist_snd /tail_of_fdist_rV fdistmap_comp.
Qed.

End fdist_col'_prop.

Section fdist_nth.
Local Open Scope vec_ext_scope.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n}) (i : 'I_n).

Definition fdist_nth : {fdist A} := fdistmap (fun v : 'rV[A]_n => v ``_ i) P.

Lemma fdist_nthE a : fdist_nth a = \sum_(x : 'rV[A]_n | x ``_ i == a) P x.
Proof. by rewrite fdistmapE. Qed.

End fdist_nth.

Section fdist_nth_prop.

Lemma head_of_fdist_rV_fdist_nth (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}) :
  head_of_fdist_rV P = fdist_nth P ord0.
Proof.
by rewrite /head_of_fdist_rV /fdist_nth /fdist_fst /head_of_fdist_rV fdistmap_comp.
Qed.

End fdist_nth_prop.

Section fdist_take.
Variable (A : finType) (n : nat) (P : {fdist 'rV[A]_n}).

Definition fdist_take (i : 'I_n.+1) : {fdist 'rV[A]_i} := fdistmap (row_take i) P.

Lemma fdist_takeE i v : fdist_take i v = \sum_(w in 'rV[A]_(n - i))
  P (castmx (erefl, subnKC (ltnS' (ltn_ord i))) (row_mx v w)).
Proof.
rewrite fdistmapE /=.
rewrite (@reindex_onto _ _ _ [finType of 'rV[A]_n] [finType of 'rV[A]_(n - i)]
  (fun w => castmx (erefl 1%nat, subnKC (ltnS' (ltn_ord i))) (row_mx v w))
  (@row_drop A n i)) /=; last first.
  move=> w wv; apply/rowP => j.
  rewrite castmxE /= cast_ord_id /row_drop mxE; case: splitP => [j0 /= jj0|k /= jik].
  - rewrite -(eqP wv) mxE castmxE /= cast_ord_id; congr (w _ _); exact: val_inj.
  - rewrite mxE /= castmxE /= cast_ord_id; congr (w _ _); exact: val_inj.
apply eq_bigl => w; rewrite inE; apply/andP; split; apply/eqP/rowP => j.
- by rewrite !mxE !castmxE /= !cast_ord_id esymK cast_ordK row_mxEl.
- by rewrite !mxE !castmxE /= cast_ord_id esymK cast_ordK cast_ord_id row_mxEr.
Qed.

End fdist_take.

Section fdist_take_prop.

Lemma fdist_take_all (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+2}) :
  fdist_take P (lift ord0 ord_max) = P.
Proof.
rewrite /fdist_take (_ : row_take (lift ord0 ord_max) = ssrfun.id) ?fdistmap_id //.
rewrite boolp.funeqE => v; apply/rowP => i.
by rewrite /row_take mxE castmxE /= cast_ord_id; congr (v _ _); exact: val_inj.
Qed.

End fdist_take_prop.
Arguments fdist_takeE {A} {n} _ _ _.

Local Open Scope vec_ext_scope.
Lemma fdist_take_nth (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}) (i : 'I_n.+1) :
  (fdist_belast_last_of_rV (fdist_take P (lift ord0 i)))`2 = fdist_nth P i.
Proof.
rewrite /fdist_snd /fdist_belast_last_of_rV /fdist_take /fdist_nth !fdistmap_comp.
congr (fdistmap _ _); rewrite boolp.funeqE => /= v /=.
by rewrite /rlast mxE castmxE /= cast_ord_id /=; congr (v ``_ _); exact: val_inj.
Qed.

Section fdistA.
Variables (A B C : finType) (P : {fdist A * B * C}).

Definition prodA (x : A * B * C) := (x.1.1, (x.1.2, x.2)).

Lemma imsetA E F G : [set prodA x | x in (E `* F) `* G] = E `* (F `* G).
Proof.
apply/setP=> -[a [b c]]; apply/imsetP/idP.
- rewrite ex2C; move=> [[[a' b'] c']] /eqP.
  rewrite /f !inE !xpair_eqE /=.
  by move=> /andP [] /eqP -> /andP [] /eqP -> /eqP -> /andP [] /andP [] -> -> ->.
- rewrite !inE /= => /andP [aE /andP [bF cG]].
  by exists ((a, b), c); rewrite // !inE /= aE bF cG.
Qed.

Definition inj_prodA : injective prodA.
Proof. by rewrite /f => -[[? ?] ?] [[? ?] ?] /= [-> -> ->]. Qed.

Definition fdistA : {fdist A * (B * C)} := fdistmap prodA P.

Lemma fdistAE x : fdistA x = P (x.1, x.2.1, x.2.2).
Proof.
case: x => a [b c]; rewrite /fdistA fdistmapE /= -/(prodA (a, b, c)) big_pred1_inj//.
exact: inj_prodA.
Qed.

Lemma fdistA_domin a b c : fdistA (a, (b, c)) = 0 -> P (a, b, c) = 0.
Proof. by rewrite fdistAE. Qed.

Lemma fdistA_dominN a b c : P (a, b, c) != 0 -> fdistA (a, (b, c)) != 0.
Proof. by apply: contra => /eqP H; apply/eqP; apply: fdistA_domin H. Qed.

End fdistA.
Arguments inj_prodA {A B C}.

Section fdistA_prop.
Variables (A B C : finType) (P : {fdist A * B * C}).
Implicit Types (E : {set A}) (F : {set B}) (G : {set C}).

Lemma fdistA1 : (fdistA P)`1 = (P`1)`1.
Proof. by rewrite /fdist_fst /fdistA 2!fdistmap_comp. Qed.

Lemma fdistA21 : ((fdistA P)`2)`1 = (P`1)`2.
Proof. by rewrite /fdistA /fdist_snd /fdist_fst /= !fdistmap_comp. Qed.

Lemma fdistA22 : ((fdistA P)`2)`2 = P`2.
Proof. by rewrite /fdistA /fdist_snd !fdistmap_comp. Qed.

Lemma fdistAX2 : (fdistX (fdistA P))`2 = (P`1)`1.
Proof. by rewrite /fdistA /fdist_snd /fdistX /fdist_fst /= 3!fdistmap_comp. Qed.

Lemma fdistAX12 : ((fdistX (fdistA P))`1)`2 = P`2.
Proof. by rewrite /fdist_snd /fdist_fst /fdistX !fdistmap_comp. Qed.

End fdistA_prop.

Section fdistC12.
Variables (A B C : finType) (P : {fdist A * B * C}).

Let f (x : A * B * C) := (x.1.2, x.1.1, x.2).

Let inj_f : injective f.
Proof. by rewrite /f => -[[? ?] ?] [[? ?] ?] /= [-> -> ->]. Qed.

Definition fdistC12 : {fdist B * A * C} := fdistmap f P.

Lemma fdistC12E x : fdistC12 x = P (x.1.2, x.1.1, x.2).
Proof.
case: x => -[b a] c; rewrite /fdistC12 fdistmapE /= -/(f (a, b, c)).
by rewrite (big_pred1_inj inj_f).
Qed.

Lemma fdistC12_snd : fdistC12`2 = P`2.
Proof. by rewrite /fdist_snd /fdistC12 fdistmap_comp. Qed.

Lemma fdistC12_fst : fdistC12`1 = fdistX (P`1).
Proof. by rewrite /fdist_fst /fdistC12 /fdistX 2!fdistmap_comp. Qed.

Lemma fdistA_C12_fst : (fdistA fdistC12)`1 = (P`1)`2.
Proof. by rewrite /fdist_fst /fdistA /fdist_snd !fdistmap_comp. Qed.

End fdistC12.

Section fdistC12_prop.
Variables (A B C : finType) (P : {fdist A * B * C}).

Lemma fdistC12I : fdistC12 (fdistC12 P) = P.
Proof.
rewrite /fdistC12 fdistmap_comp (_ : _ \o _ = ssrfun.id) ?fdistmap_id //.
by rewrite boolp.funeqE => -[[]].
Qed.

End fdistC12_prop.

Section fdistAC.
Variables (A B C : finType) (P : {fdist A * B * C}).

Definition prodAC := fun x : A * B * C => (x.1.1, x.2, x.1.2).

Lemma inj_prodAC : injective prodAC.
Proof. by move=> -[[? ?] ?] [[? ?] ?] [-> -> ->]. Qed.

Lemma imsetAC E F G : [set prodAC x | x in E `* F `* G] = E `* G `* F.
Proof.
apply/setP => -[[a c] b]; apply/imsetP/idP.
- rewrite ex2C; move=> [[[a' b'] c']] /eqP.
  by rewrite /f !inE !xpair_eqE /= => /andP [] /andP [] /eqP -> /eqP -> /eqP -> /andP [] /andP [] -> -> ->.
- by rewrite !inE /= => /andP [] /andP [] aE cG bF; exists ((a, b), c); rewrite // !inE  /= aE cG bF.
Qed.

Definition fdistAC : {fdist A * C * B} := fdistX (fdistA (fdistC12 P)).

Lemma fdistACE x : fdistAC x = P (x.1.1, x.2, x.1.2).
Proof. by case: x => x1 x2; rewrite /fdistAC fdistXE fdistAE fdistC12E. Qed.

End fdistAC.
Arguments inj_prodAC {A B C}.

Section fdistAC_prop.
Variables (A B C : finType) (P : {fdist A * B * C}).
Implicit Types (E : {set A}) (F : {set B}) (G : {set C}).

Lemma fdistAC2 : (fdistAC P)`2 = (P`1)`2.
Proof. by rewrite /fdistAC fdistX2 fdistA_C12_fst. Qed.

Lemma fdistA_AC_fst : (fdistA (fdistAC P))`1 = (fdistA P)`1.
Proof. by rewrite /fdist_fst !fdistmap_comp. Qed.

Lemma fdistA_AC_snd : (fdistA (fdistAC P))`2 = fdistX ((fdistA P)`2).
Proof. by rewrite /fdist_snd /fdistX !fdistmap_comp. Qed.

Lemma fdistAC_fst_fst : ((fdistAC P)`1)`1 = (P`1)`1.
Proof. by rewrite /fdist_fst !fdistmap_comp. Qed.

End fdistAC_prop.

Section fdistC13.
Variables (A B C : finType) (P : {fdist A * B * C}).

Definition fdistC13 : {fdist C * B * A} := fdistC12 (fdistX (fdistA P)).

Lemma fdistC13E x : fdistC13 x = P (x.2, x.1.2, x.1.1).
Proof. by rewrite /fdistC13 fdistC12E fdistXE fdistAE. Qed.

Lemma fdistC13_fst : fdistC13`1 = fdistX ((fdistA P)`2).
Proof. by rewrite /fdistC13 /fdist_fst /fdistX !fdistmap_comp. Qed.

Lemma fdistC13_snd : fdistC13`2 = (P`1)`1.
Proof. by rewrite /fdistC13 fdistC12_snd fdistAX2. Qed.

Lemma fdistC13_fst_fst : (fdistC13`1)`1 = P`2.
Proof. by rewrite /fdist_fst /fdist_snd !fdistmap_comp. Qed.

Lemma fdistA_C13_snd : (fdistA fdistC13)`2 = fdistX (P`1).
Proof. by rewrite /fdist_snd /fdistX !fdistmap_comp. Qed.

End fdistC13.

Section fdist_proj13.
Variables (A B C : finType) (P : {fdist A * B * C}).

Definition fdist_proj13 : {fdist A * C} := (fdistA (fdistC12 P))`2.

Lemma fdist_proj13E x : fdist_proj13 x = \sum_(b in B) P (x.1, b, x.2).
Proof.
by rewrite /fdist_proj13 fdist_sndE; apply eq_bigr => b _; rewrite fdistAE fdistC12E.
Qed.

Lemma fdist_proj13_domin a b c : fdist_proj13 (a, c) = 0 -> P (a, b, c) = 0.
Proof. by rewrite fdist_proj13E /= => /psumR_eq0P ->. Qed.

Lemma fdist_proj13_dominN a b c : P (a, b, c) != 0 -> fdist_proj13 (a, c) != 0.
Proof. by apply: contra => /eqP H; apply/eqP/fdist_proj13_domin. Qed.

Lemma fdist_proj13_snd : fdist_proj13`2 = P`2.
Proof. by rewrite /fdist_proj13 fdistA22 fdistC12_snd. Qed.

Lemma fdist_proj13_fst : fdist_proj13`1 = (fdistA P)`1.
Proof. by rewrite /fdist_proj13 fdistA21 fdistC12_fst fdistX2 fdistA1. Qed.

End fdist_proj13.

Section fdist_proj23.
Variables (A B C : finType) (P : {fdist A * B * C}).

Definition fdist_proj23 : {fdist B * C} := (fdistA P)`2.

Lemma fdist_proj23E x : fdist_proj23 x = \sum_(a in A) P (a, x.1, x.2).
Proof.
by rewrite /fdist_proj23 fdist_sndE; apply eq_bigr => a _; rewrite fdistAE.
Qed.

Lemma fdist_proj23_domin a b c : fdist_proj23 (b, c) = 0 -> P (a, b, c) = 0.
Proof. by rewrite fdist_proj23E /= => /psumR_eq0P ->. Qed.

Lemma fdist_proj23_dominN a b c : P (a, b, c) != 0 -> fdist_proj23 (b, c) != 0.
Proof. by apply: contra => /eqP H; apply/eqP; apply: fdist_proj23_domin. Qed.

Lemma fdist_proj23_fst : fdist_proj23`1 = (P`1)`2.
Proof. by rewrite /fdist_proj23 fdistA21. Qed.

Lemma fdist_proj23_snd : fdist_proj23`2 = P`2.
Proof. by rewrite /fdist_proj23 fdistA22. Qed.

End fdist_proj23.

Lemma fdist_proj13_AC (A B C : finType) (P : {fdist A * B * C}) :
  fdist_proj13 (fdistAC P) = P`1.
Proof.
rewrite /fdist_proj13 /fdist_snd /fdistA /fdistC12 /fdistAC /fdist_fst.
rewrite !fdistmap_comp /=; congr (fdistmap _ _).
by rewrite boolp.funeqE => -[[]].
Qed.

Section fdist_self.
Variable (A : finType) (P : {fdist A}).

Let f := [ffun a : A * A => if a.1 == a.2 then P a.1 else 0].

Let f0 x : 0 <= f x.
Proof. rewrite /f ffunE; case: ifPn => [/eqP -> //| _]; exact: leRR. Qed.

Let f1 : \sum_(x in {: A * A}) f x = 1.
Proof.
rewrite (eq_bigr (fun a => f (a.1, a.2))); last by case.
rewrite -(pair_bigA _ (fun a1 a2 => f (a1, a2))) /=.
rewrite -(FDist.f1 P); apply/eq_bigr => a _.
under eq_bigr do rewrite ffunE.
rewrite /= (bigD1 a) //= eqxx.
by rewrite big1 ?addR0 // => a' /negbTE; rewrite eq_sym => ->.
Qed.

Definition fdist_self : {fdist A * A} := locked (FDist.make f0 f1).

Lemma fdist_selfE a : fdist_self a = if a.1 == a.2 then P a.1 else 0.
Proof. by rewrite /fdist_self; unlock; rewrite ffunE. Qed.

End fdist_self.

Section fdist_self_prop.
Variables (A : finType) (P : {fdist A}).

Lemma fdist_self1 : (fdist_self P)`1 = P.
Proof.
apply/fdist_ext => a /=; rewrite fdist_fstE (bigD1 a) //= fdist_selfE eqxx /=.
by rewrite big1 ?addR0 // => a' /negbTE; rewrite fdist_selfE /= eq_sym => ->.
Qed.

Lemma fdistX_self : fdistX (fdist_self P) = fdist_self P.
Proof.
apply/fdist_ext => -[a1 a2].
by rewrite fdistXE !fdist_selfE /= eq_sym; case: ifPn => // /eqP ->.
Qed.

End fdist_self_prop.

Local Open Scope ring_scope.
(* TODO: rm? *)
Lemma rsum_rmul_rV_pmf_tnth A n k (P : fdist A) :
  \sum_(t : 'rV[ 'rV[A]_n]_k) \prod_(m < k) (P `^ n) t ``_ m = 1.
Proof.
transitivity (\sum_(j : {ffun 'I_k -> 'rV[A]_n}) \prod_(m : 'I_k) P `^ _ (j m)).
  rewrite (reindex_onto (fun p : 'rV_k => [ffun i => p ``_ i])
    (fun x : {ffun 'I_k -> 'rV_n} => \row_(i < k) x i)) //=; last first.
    by move=> f _; apply/ffunP => /= k0; rewrite ffunE mxE.
  apply eq_big => //.
  - by move=> v /=; apply/esym/eqP/rowP => i; rewrite mxE ffunE.
  - by move=> i _; apply eq_bigr => j _; rewrite ffunE.
rewrite -(bigA_distr_bigA (fun m => P `^ _)) /= big_const.
by rewrite iter_mulR FDist.f1 exp1R.
Qed.
Local Close Scope ring_scope.
Local Close Scope vec_ext_scope.

(* wip *)
Module Subvec.
Section def.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n}) (s : {set 'I_n}).
Definition d : {fdist 'rV[A]_#|s| } := fdistmap (fun x => sub_vec x s) P.
End def.
End Subvec.
Section subvec_prop.
Local Open Scope vec_ext_scope.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}).
Definition marginal1_cast (i : 'I_n.+1) (v : 'rV[A]_#|[set i]|) : A :=
  (castmx (erefl, cards1 i) v) ``_ ord0.
Lemma head_ofE :
  head_of_fdist_rV P = fdistmap (@marginal1_cast ord0) (@Subvec.d A n.+1 P [set ord0]).
Proof.
apply fdist_ext => a.
rewrite fdistmapE /= /head_of_fdist_rV fdist_fstE /= /head_of_fdist_rV.
under eq_bigr do rewrite fdistmapE /=.
rewrite /Subvec.d.
under [in RHS] eq_bigr do rewrite fdistmapE /=.
Abort.
End subvec_prop.

Section fdist_prod_nth.
Local Open Scope vec_ext_scope.
Variables (A B : finType) (n : nat) (P : {fdist 'rV[A]_n * B}) (i : 'I_n).

Definition fdist_prod_nth : {fdist A * B} :=
  fdistmap (fun x : 'rV[A]_n * B => (x.1 ord0 i, x.2)) P.

Lemma fdist_prod_nthE ab :
  fdist_prod_nth ab = \sum_(x : 'rV[A]_n * B | (x.1 ``_ i == ab.1) && (x.2 == ab.2)) P x.
Proof. by rewrite fdistmapE. Qed.

End fdist_prod_nth.

Section fdist_prod_take.
Variables (A B : finType) (n : nat) (P : {fdist 'rV[A]_n.+1 * B}) (i : 'I_n.+1).

Definition fdist_prod_take : {fdist 'rV_i * A * B} :=
  fdistmap (fun x : 'rV[A]_n.+1 * B => (row_take (widen_ord (leqnSn _) i) x.1, x.1 ord0 i, x.2)) P.

End fdist_prod_take.

Section to_bivar_last_take.

Variables (A B : finType).
Variables (n : nat) (PY : {fdist 'rV[A]_n.+1 * B}).
Let P : {fdist 'rV[A]_n.+1} := PY`1.

Lemma belast_last_take (j : 'I_n.+1) :
  fdist_belast_last_of_rV (fdist_take P (lift ord0 j)) = (fdist_prod_take PY j)`1.
Proof.
rewrite /fdist_belast_last_of_rV /fdist_take /fdist_fst /fdist_prod_take !fdistmap_comp.
congr (fdistmap _ PY); rewrite boolp.funeqE => /= -[v b] /=; congr (_, _).
- apply/rowP => i.
  by rewrite /rbelast !mxE !castmxE /=; congr (v _ _); exact: val_inj.
- by rewrite /rlast mxE castmxE /=; congr (v _ _); exact: val_inj.
Qed.

End to_bivar_last_take.

Section fdist_take_drop.
Local Open Scope vec_ext_scope.
Variables (A : finType) (n : nat) (P : {fdist 'rV[A]_n.+1}) (i : 'I_n.+1).

Definition fdist_take_drop : {fdist A * 'rV[A]_i * 'rV[A]_(n - i)} :=
  fdistmap (fun x : 'rV[A]_n.+1 =>
            (x ord0 ord0, row_take i (rbehead x), row_drop i (rbehead x))) P.

Let g (x : 'rV[A]_n.+1) : A * 'rV[A]_i * 'rV[A]_(n - i) :=
  (x ``_ ord0,
   row_take i (rbehead x),
   row_drop i (rbehead x)).

Let inj_g : injective g.
Proof.
move=> a b; rewrite /g => -[H1 H2 H3].
rewrite -(row_mx_rbehead a) -(row_mx_rbehead b) H1; congr (@row_mx _ 1%nat 1%nat _ _ _).
rewrite (row_mx_take_drop i (rbehead a)) (row_mx_take_drop i (rbehead b)).
by rewrite H2 H3.
Qed.

Lemma fdist_take_dropE x : fdist_take_drop x = P (row_mx (\row_(_ < 1) x.1.1)
                               (castmx (erefl 1%nat, @subnKC i n (ltnS' (ltn_ord i)))
                               (row_mx x.1.2 x.2))).
Proof.
rewrite /fdist_take_drop fdistmapE /=.
rewrite (eq_bigl (fun a : 'rV_n.+1 => (g a == x)%bool)) //.
rewrite {1}(_ : x = g (row_mx (\row_(k<1) x.1.1)
                                 (castmx (erefl 1%nat, subnKC (ltnS' (ltn_ord i)))
                                 (row_mx x.1.2 x.2)))); last first.
  move: x => /= -[[x11 x12] x2].
  rewrite /g row_mx_row_ord0 /=; congr (_, _, _).
  apply/rowP => j; rewrite !mxE !castmxE /= cast_ord_id mxE esymK.
  have @k : 'I_n.
    by apply: (@Ordinal _ j); rewrite (leq_trans (ltn_ord j)) // -ltnS.
  rewrite (_ : lift _ _ = rshift 1%nat k); last first.
    by apply val_inj => /=; rewrite /bump leq0n.
  rewrite (@row_mxEr _ 1%nat 1%nat) // castmxE /= cast_ord_id.
  rewrite (_ : cast_ord _ k = lshift (n - i) j).
  by rewrite row_mxEl.
  exact: val_inj.
  apply/rowP => j; rewrite mxE castmxE /= cast_ord_id mxE esymK.
  have @k0 : 'I_n by apply: (@Ordinal _ (i + j)); rewrite -ltn_subRL.
  rewrite (_ : lift _ _ = rshift 1%nat k0); last first.
    apply val_inj => /=; by rewrite /bump leq0n.
  rewrite (@row_mxEr _ 1%nat 1%nat) castmxE /=.
  rewrite (_ : cast_ord _ _ = rshift i j); last exact: val_inj.
  by rewrite row_mxEr cast_ord_id.
by rewrite (big_pred1_inj inj_g).
Qed.

End fdist_take_drop.

(*Section tuple_prod_cast.

Variables A B : finType.
Variable n : nat.
Variable P : {dist 'rV[A * B]_n}.

(*
Definition dist_tuple_prod_cast : dist [finType of n.-tuple A * n.-tuple B].
apply makeDist with (fun xy => P (prod_tuple xy)).
move=> a; by apply Rle0f.
rewrite -(pmf1 P).
rewrite (reindex_onto (fun x => tuple_prod x) (fun y => prod_tuple y)); last first.
  move=> i _; by rewrite prod_tupleK.
rewrite /=.
apply eq_big => /= i.
- by rewrite inE tuple_prodK eqxx.
- move=> _; by rewrite tuple_prodK.
Defined.
*)

End tuple_prod_cast.*)

