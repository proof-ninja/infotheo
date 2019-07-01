Require Import ssreflect ssrfun ssrbool eqtype ssrnat div seq.
Require Import path choice fintype tuple finfun finset bigop.
Require Import Reals Fourier.
Require Import Reals_ext log2 ssr_ext Rbigop proba entropy aep typ_seq natbin Rssr ceiling v_source_code.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope tuple_ext_scope.
Local Open Scope typ_seq_scope.
Local Open Scope proba_scope.
Local Open Scope reals_ext_scope.
Local Open Scope entropy_scope.

Section R_lemma.
Variable (X : finType) (n' : nat).
Variable f0 : X -> R.
Let n := n'.+1.
Variable S : {set  X}.

Lemma rsum_mulRC g Cond: \rsum_(i| Cond  i) f0 i * g i = \rsum_(i| Cond i) g i * f0 i.
Proof.  by apply: eq_bigr=>? _; rewrite mulRC. Qed.

Lemma rsum_union':
  \rsum_(x| x \in X) f0 x = \rsum_(x| x \in S ) f0 x + \rsum_(x| x \in ~: S) f0 x.
Proof.
rewrite [X in X = _] (_ : _ = \rsum_(x in [set : X]) f0(x)).
-apply: rsum_union.
 +by rewrite disjoints_subset setCS.
 +by apply/setP => ?; rewrite !inE orbN.
-by apply: eq_bigl => ?; rewrite in_setT.
Qed.

Lemma log_pow_INR m k : (m > 0)%nat -> 
  log (INR (m ^ k)) = (INR k) * log (INR m).
Proof. 
move => Hyp.
elim: k => [| k IH].
-by rewrite mul0R expn0 log_1.
-rewrite expnS mult_INR log_mult.
 +by rewrite IH -addn1 plus_INR mulRDl addRC mul1R.
 +by apply: lt_0_INR;  apply/ltP.
 +by apply: lt_0_INR; apply/ltP; rewrite expn_gt0 /orb Hyp.
Qed.

Lemma R3neqR0 : 3 <> 0.
Proof.
  by apply: nesym;apply: Rlt_not_eq; apply: Rplus_lt_pos; [apply: Rlt_0_1 | apply: Rlt_0_2].
Qed.

Lemma zero_ge_4 : 0 < 4.
Proof. by apply: Rmult_lt_0_compat; apply: Rlt_0_2. Qed.

Lemma R4neqR0 : 4 <> 0.
Proof.  by apply: Rgt_not_eq; apply: zero_ge_4. Qed.

Lemma elevenOverTwelve_le_One : / 4+ / 3 + / 3 < 1.
Proof.
  move : R3neqR0 R4neqR0 => ? ?.
  apply: (Rmult_lt_reg_r 3); first by apply: Rplus_lt_pos; [apply: Rlt_0_1 | apply: Rlt_0_2].
  rewrite Rmult_plus_distr_r Rmult_plus_distr_r -Rinv_l_sym // mul1R mulRC.
  apply: (Rmult_lt_reg_r 4); first  by apply: Rmult_lt_0_compat; apply: Rlt_0_2.
  rewrite 2! Rmult_plus_distr_r -mulRA -Rinv_l_sym //=.
  rewrite !mulR1 !Rmult_plus_distr_r !Rmult_plus_distr_l !mulR1.
  rewrite addRC; apply: Rplus_lt_compat_l.
  rewrite addRC; apply: Rplus_lt_compat_l.
  by apply: Rplus_lt_compat_r; apply: Rlt_plus_1.
Qed.

End R_lemma.

Section Length.
Variable (X : finType) (n' : nat).
Let n := n'.+1.
Variable P : dist X.
Variable epsilon : R.
Hypothesis eps_pos : 0 < epsilon.

Lemma leng_neq_0 : INR n <> 0.
Proof.
 by apply: nesym; apply: Rlt_not_eq; apply: lt_0_INR; apply/ltP.
Qed.

Lemma dist_support_LB : 1 <= INR #|X|.
Proof.
rewrite (_ : 1 = INR 1)  //; apply: le_INR; apply/leP. 
by apply: (dist_support_not_empty P).
Qed.

Lemma dist_supp_lg_add_1_neq_0 : 1 + log (INR #|X|) <> 0.
Proof.
by apply: nesym; apply: Rlt_not_eq; apply: (Rplus_lt_le_0_compat _ _ Rlt_0_1);
 rewrite -log_1; apply: (log_increasing_le Rlt_0_1); apply: dist_support_LB.
Qed.

Definition L_typ := ceil (INR n * (`H P + epsilon)).
Definition L_not_typ :=  ceil (log (INR #| [set : n.-tuple X]|)).

Lemma Lt_pos : 0 < IZR L_typ.
Proof.
apply: (Rlt_le_trans _ (INR n * (`H P + epsilon))); last by rewrite /L_typ ; apply: ceil_bottom.
rewrite -(mulR0 0).
apply: (Rmult_le_0_lt_compat _ _ _ _ (Rle_refl _) (Rle_refl _)).
- by apply: lt_0_INR; apply/ltP.
- by apply(Rplus_le_lt_0_compat _ _ (entropy_pos P) eps_pos).
Qed.

Lemma Lnt_nonneg: 0 <= IZR L_not_typ.
Proof.
apply: (Rle_trans _ (log (INR #|[set: n.-tuple X]|))); last by rewrite /L_not_typ; apply: ceil_bottom.
rewrite -log_1; apply: (log_increasing_le Rlt_0_1).
rewrite cardsT card_tuple -INR_pow_expn.
by apply: pow_R1_Rle; apply: dist_support_LB. 
Qed.

Lemma card_le_TS_Lt : INR #| `TS P n epsilon | <= INR #|[ set : (Zabs_nat L_typ).-tuple bool]|. 
Proof.
apply: (Rle_trans _ _ _ (TS_sup _ _ _)).
rewrite cardsT /= card_tuple  /=  card_bool.
rewrite -exp2_pow2.
apply: exp2_le_increasing.
rewrite INR_Zabs_nat.
- by apply: ceil_bottom.
- by apply: le_IZR; apply: RltW; apply: Lt_pos.
Qed.

Lemma card_le_Xn_Lnt' : INR #| [set: n.-tuple X]| <= INR #| [set: (Zabs_nat L_not_typ).-tuple bool]|.
Proof.
have fact : log (INR (#|X| ^ n)) <= IZR (ceil (log (INR (#|X|^n)))) by apply: ceil_bottom.
rewrite /L_not_typ cardsT card_tuple.
rewrite {1}(_ :  INR (#|X| ^ n) = exp2 (log ( INR (#|X|^n)))).
-rewrite cardsT card_tuple card_bool -exp2_pow2.
 apply: exp2_le_increasing.
 rewrite /L_not_typ INR_Zabs_nat //.
 apply: le_IZR; apply: (Rle_trans _ (log (INR (#|X|^n)))) => //.
 rewrite /= -log_1; apply: (log_increasing_le Rlt_0_1).
 rewrite -INR_pow_expn.
 by apply: pow_R1_Rle; apply: dist_support_LB. 
-rewrite exp2_log //; last rewrite -INR_pow_expn.
 apply: pow_lt.
 by apply: (Rlt_le_trans _ 1 _ Rlt_0_1 dist_support_LB).
Qed.

End Length.

Section Enc_Dec.
Variable (X : finType) (n' : nat).
Let n := n'.+1.
Variable P : dist X.
Variable epsilon : R.
Hypothesis eps_pos : 0 < epsilon.

Local Notation "'L_typ'" := (L_typ n' P epsilon).
Local Notation "'L_not_typ'" := (L_not_typ X n').

Definition enc_typ x :=
 let i := seq.index x (enum (`TS P n epsilon))
 in Tuple (size_nat2bin i (Zabs_nat L_typ)).

Lemma  card_le_Xn_Lnt :
  (#|[finType of n.-tuple X] | <= #|[finType of (Zabs_nat L_not_typ).-tuple bool]|)%nat.
Proof.
 rewrite -!cardsT.
 apply/leP. 
 apply: (INR_le _ _ (card_le_Xn_Lnt' n' P)).
Qed.

Definition enc_not_typ x := enum_val (widen_ord card_le_Xn_Lnt (enum_rank x)).

Lemma inj_enc_not_typ : injective enc_not_typ.
Proof. by move=> a1 a2 /enum_val_inj [] /ord_inj/enum_rank_inj. Qed.

Definition f : var_enc X n := fun x =>
  if x \in `TS P n epsilon then
    true :: enc_typ x
  else 
    false :: enc_not_typ x.

Lemma f_inj : injective f.
Proof.
have card_TS_Lt :  (#|`TS P n epsilon| <= (2 ^ Z.abs_nat L_typ))%nat.
  by apply/leP;  apply: INR_le; move: (card_le_TS_Lt n' P eps_pos); 
       rewrite {1}cardsT card_tuple /= card_bool.
move=> t1 t2; rewrite /f.
case/boolP : (t1 == t2) ; first by move /eqP.
move=> mainCase.
case: ifP=>?; case: ifP=>? //; case=> H; last by apply: inj_enc_not_typ; apply: val_inj.
-  have {H}H : seq.index t1 (enum (`TS P n epsilon)) =
              seq.index t2 (enum (`TS P n epsilon))
     by apply: (nat2bin_inj (Zabs_nat L_typ)) => //;  apply: (leq_trans _ card_TS_Lt);
     apply: seq_index_enum_card => //;  apply: enum_uniq.
 rewrite -(@nth_index _ t1 t1 (enum (`TS P n epsilon))); last by rewrite mem_enum.
 rewrite -(@nth_index _ t1 t2 (enum (`TS P n epsilon))); last by rewrite mem_enum.
 by rewrite H.
Qed.

Definition phi_def : n.-tuple X.
move Hpick : [pick x | x \in [set: X] ] => p;
move: Hpick; case: (pickP _)=>[x _ _ | abs]; first apply: [tuple of nseq n x].
suff : False by [].
move: (dist_support_not_empty P).
rewrite -cardsT card_gt0; case/set0Pn => ?.
by rewrite abs.
Defined.

Definition phi: var_dec X n := fun y =>
 if [ pick x | f x == y ] is Some x then x else phi_def.

Lemma phi_f x : phi (f x) = x.
Proof.
rewrite /phi.
case:(pickP _)=> [x0 /eqP | H].
-by apply: f_inj.
-by move: (H x); rewrite eqxx.
Qed.

Definition extension (enc : var_enc X n) (x : seq (n.-tuple X)) :=
flatten (map enc x).

Lemma ext_uniq_decodable : injective (extension f).
Proof.
elim => [ | a la H ]; case => [|b lb]; rewrite /extension /= /f //=; 
 [by case : ifP |by case : ifP | ].
case: ifP  => aT; case: ifP=> bT //;  move /eqP; rewrite -/f eqseq_cat.
 +by case/andP=>[/eqP eq_ab ] /eqP /H ->; congr (_ :: _); apply: f_inj; rewrite /f aT bT.
 +by rewrite /= !/nat2bin !size_pad_seqL.
 +by case/andP=>[/eqP eq_ab ] /eqP /H ->; congr (_ :: _); apply: f_inj; rewrite /f aT bT.
 +by rewrite !size_tuple.
Qed. 

End Enc_Dec.

Section E_Leng_Cw_Lemma.
Variable (X : finType).

Definition E_leng_cw (n : nat) (f : var_enc X n) (P : dist X):= 
  \rsum_(x in [finType of n.-tuple X])( P `^ n (x) * (INR (size (f x)))).

Lemma E_leng_cw' (n : nat) (f : var_enc X n) (P : dist X): 
  E_leng_cw f P = `E (mkRvar (P `^ n) (fun x => INR (size (f x)))).
Proof. by rewrite /E_leng_cw /Ex_alt /= rsum_mulRC. Qed.

Variable (n' : nat).
Let n := n'.+1.
Variable P : dist X.
Variable epsilon:R.
Hypothesis eps_pos: 0 < epsilon.
Hypothesis aepbound_UB : aep_bound P epsilon <= INR n.

Local Notation "'L_typ'" := (L_typ n' P epsilon).
Local Notation "'L_not_typ'" := (L_not_typ X n').

Lemma eq_sizef_Lt :
  \rsum_(x| x \in `TS P n epsilon) P `^ n (x) * (INR (size (f P epsilon x)) ) =
  \rsum_(x| x \in `TS P n epsilon) P `^ n (x) * (IZR L_typ + 1).
Proof.
apply: eq_bigr=> i H.
apply: Rmult_eq_compat_l.
rewrite /f H /= size_pad_seqL -INR_Zabs_nat.
-by rewrite -addn1; rewrite plus_INR.
-by apply: le_IZR;apply: RltW; apply: Lt_pos.
Qed.

Lemma eq_sizef_Lnt:
  \rsum_(x| x \in ~:(`TS P n epsilon)) P `^ n (x) * (INR (size (f P epsilon x)) )
  = \rsum_(x| x \in ~:(`TS P n epsilon)) P `^ n (x) * (IZR L_not_typ + 1) .
Proof.
apply: eq_bigr => ? H.
apply: Rmult_eq_compat_l.
move: H; rewrite in_setC.
rewrite /f; move /negbTE ->.
rewrite /= -addn1 size_tuple plus_INR INR_Zabs_nat.
-by [].
-by apply: le_IZR; apply: (Lnt_nonneg _ P).
Qed.

Lemma E_leng_cw_le_Length : E_leng_cw (f (n':=n') P epsilon) P <= (IZR L_typ + 1)
 + epsilon * (IZR L_not_typ + 1) .
Proof.
rewrite /E_leng_cw (rsum_union' _ (`TS P n'.+1 epsilon)).
rewrite eq_sizef_Lnt eq_sizef_Lt -!(big_morph _ (morph_mulRDl _) (mul0R _)) mulRC.
rewrite (_ : \rsum_(i | i \in ~: `TS P n epsilon)
 P `^ n i = 1 - \rsum_(i | i \in `TS P n epsilon) P `^ n i); last first. 
-by rewrite -(pmf1 P`^n) (rsum_union' _ (`TS P n epsilon)) addRC /Rminus
       -addRA Rplus_opp_r addR0.
-apply: Rplus_le_compat.
 +rewrite -[X in _ <= X]mulR1; apply: Rmult_le_compat_l. 
  *by apply: (Rplus_le_le_0_compat _ _ _ Rle_0_1); apply: RltW; apply: Lt_pos.
  *by rewrite -(pmf1 P`^ n); apply: Rle_big_f_X_Y=> //; move=> ?; apply: Rle0f.
 +apply: Rmult_le_compat_r.
  *by apply: (Rplus_le_le_0_compat _ _ (Lnt_nonneg _ P) Rle_0_1).
  *apply: Rminus_le; rewrite /Rminus addRC addRA; apply: Rle_minus; rewrite addRC.
    by apply: Rge_le; apply: Pr_TS_1.
Qed.

End E_Leng_Cw_Lemma.

Section v_scode.
Variable (X : finType) (n' : nat).
Let n := n'.+1.
Variable P : dist X.
Variable epsilon : R.
Hypothesis eps_pos : 0 < epsilon .
Definition epsilon':= epsilon / (3 + (3 * log (INR #|X|))).
Definition n0 := maxn (Zabs_nat (ceil (INR 2 / (INR 1 + log (INR #|X|))))) 
                     (maxn (Zabs_nat (ceil (8 / epsilon)))
                     (Zabs_nat (ceil (aep_sigma2 P/ epsilon' ^ 3)))).
Hypothesis n0_Le_n : (n0 < n)%nat.

Lemma n0_eps3 :  2 * (epsilon / (3 * (1 + log (INR #|X|)))) / INR n < epsilon / 3.
Proof.
move : (@leng_neq_0 n') (dist_supp_lg_add_1_neq_0 P) R3neqR0 => ? ? ?.
rewrite mulRC /Rdiv -?mulRA; apply: (Rmult_lt_compat_l _ _ _ eps_pos); rewrite ?mulRA (mulRC _ 2).
apply: (Rmult_lt_reg_l 3); first by apply: Rplus_lt_pos; [apply: Rlt_0_1 | apply: Rlt_0_2].
rewrite Rinv_mult_distr //  ?mulRA (mulRC 3 2) Rinv_r_simpl_l //.
apply: (Rmult_lt_reg_l (INR n)); first by apply: lt_0_INR; apply/ltP.
rewrite mulRC -mulRA (mulRC _ (INR n)) ?mulRA Rinv_r_simpl_l // Rinv_r_simpl_l //.
apply: (Rle_lt_trans _ _ _ (ceil_bottom _)).
rewrite -INR_Zabs_nat.
-apply: (lt_INR _ _).
 move : n0_Le_n; rewrite /n0 gtn_max.
 by case/andP => /ltP.
-apply: le_IZR;apply: (Rle_trans _ (2 * / (1 + log (INR #|X|)))); last by apply: ceil_bottom.
 apply: Rmult_le_pos; first by apply: RltW; apply: Rlt_0_2.
 apply: Rlt_le; apply: Rinv_0_lt_compat.
 apply: (Rplus_lt_le_0_compat _ _ Rlt_0_1).
 rewrite -log_1.
 apply: (log_increasing_le Rlt_0_1).
 by apply: dist_support_LB.
Qed.

Lemma n0_eps4 :  2 * / INR n  < epsilon / 4.
Proof.
move: (@leng_neq_0 n') R4neqR0 zero_ge_4 => ? ? ?.
have Fact8 : 4 * 2 = 8 by rewrite mulRA.
move: n0_Le_n; rewrite /n0 !gtn_max;  case/andP=> _;  case/andP=> Hyp _.
apply: (Rmult_lt_reg_l 4) => //.
rewrite /Rdiv (mulRC epsilon (/ 4)) mulRA mulRA Rinv_r // Fact8 mul1R.
apply: (Rmult_lt_reg_l (INR n)); first by apply: lt_0_INR; apply/ltP. 
rewrite mulRA (mulRC _ 8) Rinv_r_simpl_l //.
apply: (Rmult_lt_reg_l ( / epsilon)); first by apply: Rinv_0_lt_compat.
rewrite mulRC (mulRC (/ epsilon) (INR n * epsilon)) Rinv_r_simpl_l;
 last by apply: nesym; apply: Rlt_not_eq=>//.
apply: (Rle_lt_trans _ (IZR (ceil (8 * / epsilon))) _ (ceil_bottom _)).
rewrite -INR_Zabs_nat.
-by apply: lt_INR; apply/ltP.
-apply: le_IZR;apply: (Rle_trans _ (8 * / epsilon)); last  by apply: ceil_bottom.
 apply: Rle_mult_inv_pos ; last by apply eps_pos.
 by apply: Rmult_le_pos; apply: RltW ; [apply: Rlt_0_2 | apply: zero_ge_4]. 
Qed.

Lemma eps'_pos : 0 < epsilon'.
Proof. 
rewrite /epsilon' /Rdiv -(mulR0 epsilon).
apply: Rmult_lt_compat_l=>//.
apply: Rinv_0_lt_compat.
apply: Rplus_lt_le_0_compat; first by apply: (Rlt_zero_pos_plus1 _ Rlt_R0_R2).
apply: Rmult_le_pos; first by apply: Rle_zero_pos_plus1; apply: (Rle_zero_pos_plus1 _ Rle_0_1).
rewrite -log_1.
by apply: (log_increasing_le Rlt_0_1 (dist_support_LB P)).
Qed.

Lemma le_aepbound_n : aep_bound P epsilon' <= INR n.
Proof.
rewrite /aep_bound .
apply: (Rle_trans _ _ _ (ceil_bottom _)).
rewrite -INR_Zabs_nat.
  apply: RltW; apply: lt_INR.
  move: n0_Le_n.
  rewrite /n0 !gtn_max.
  case/andP=> _. 
  case/andP=> _ H2.
  by apply/ltP.
apply: le_IZR; apply: (Rle_trans _ (aep_sigma2 P / epsilon' ^ 3)); last by apply: (ceil_bottom _).
apply: Rmult_le_pos; first by apply: aep_sigma2_pos.
by apply: Rlt_le; apply: Rinv_0_lt_compat; apply: (pow_lt _ _ eps'_pos).
Qed. 

Lemma lb_entro_plus_eps :
 IZR (L_typ n' P epsilon') + 1 + epsilon' * (IZR (L_not_typ X n') + 1) <
   (`H P + epsilon) * INR n.
Proof.
move : (@leng_neq_0 n') (dist_supp_lg_add_1_neq_0 P) R3neqR0 R4neqR0 => ? ? ? ?.
rewrite /L_typ /L_not_typ.
apply: (Rle_lt_trans _  (INR n'.+1 * (`H P + epsilon') + 1 + 1 +
   epsilon' * (log (INR #|[set: (n'.+1).-tuple X]|) + 1 + 1))).
-apply: Rplus_le_compat.
 +by apply: Rplus_le_compat; [apply: RltW; apply: ceil_upper | apply: Rle_refl].
 +apply: Rmult_le_compat_l; first by apply: Rlt_le; apply: eps'_pos.
   by apply: Rplus_le_compat; [apply: RltW; apply: ceil_upper | apply: Rle_refl].
 -rewrite cardsT card_tuple log_pow_INR; last by apply: (dist_support_not_empty P).
  rewrite -addRA -addRA -addRA addRC addRA addRC addRA  -(Rinv_r_simpl_l (INR n) 2) //.
  rewrite (mulRC 2 _) -{1}mulRA -Rmult_plus_distr_l -mulRA -Rmult_plus_distr_l
   (mulRC epsilon' _) -mulRA (mulRC _ epsilon') -Rmult_plus_distr_l mulRC.
  apply: Rmult_lt_compat_r; first by apply: lt_0_INR; apply/ltP.
  rewrite -addRA -addRA; apply: Rplus_lt_compat_l.
  rewrite Rmult_plus_distr_l (addRC (epsilon' * log (INR #|X|)) _) addRC addRA
   -addRA (addRC _ epsilon') -{2}(mulR1 epsilon') -Rmult_plus_distr_l
   -addRA (addRC (epsilon' * (2 / INR n)) _) addRA addRC  mulRC addRC /epsilon'
   -{1}(mulR1 3) -{3}(mulR1 3) -Rmult_plus_distr_l /Rdiv {1}(Rinv_mult_distr) //
   mulRA -mulRA -Rinv_l_sym // mulR1.
  apply: (Rle_lt_trans _ (epsilon / 4 + epsilon * / 3 + epsilon / 3)).
  *apply: Rplus_le_compat.
   +by apply: Rplus_le_compat; [apply: RltW; apply: n0_eps4 | apply: Rle_refl].
   +by rewrite mulRC /Rdiv (mulRC 2 _) mulRA mulRC mulRA; apply: RltW; apply: n0_eps3.
  rewrite /Rdiv -?Rmult_plus_distr_l -{2}(mulR1 epsilon);  apply: (Rmult_lt_compat_l _ _ _ eps_pos).
by apply: elevenOverTwelve_le_One.
Qed.

Lemma v_scode' : exists (f : var_enc X n) (phi : var_dec X n) , 
                         (forall x, phi (f x) = x) /\
                         (E_leng_cw f P) / (INR n) < (`H P + epsilon).
Proof.
move : (@leng_neq_0 n') (dist_supp_lg_add_1_neq_0 P) R3neqR0 R4neqR0 => ? ? ? ?.
apply: (ex_intro _ (f P epsilon')).
apply: (ex_intro _ (phi n' P epsilon')).
 -apply: conj=> [ x |]; first by apply: (phi_f _ eps'_pos).
   apply: (Rmult_lt_reg_r (INR n)); first by apply: lt_0_INR; apply/ltP.
   rewrite /Rdiv -mulRA -(mulRC (INR n)) Rinv_r // mulR1.
   apply: (Rle_lt_trans _ (IZR (L_typ n' P epsilon') + 1 + epsilon' * (IZR (L_not_typ X n') + 1))).
   +by apply: E_leng_cw_le_Length;[apply: eps'_pos | apply: le_aepbound_n].
   +by apply: lb_entro_plus_eps.
Qed.

End v_scode.

Section variable_length_source_coding.

Variable (X : finType) (n' : nat).
Let n :=n'.+1.
Variable P : dist X.
Variable epsilon : R.
Hypothesis eps_pos : 0 < epsilon .
Local Notation "'n0'" := (n0 P epsilon).

Theorem v_scode_direct : exists m: nat, (m < n)%nat -> 
  exists f : var_enc X n,
    injective f /\
    E_leng_cw f P / INR n < `H P + epsilon.
Proof.
apply: (ex_intro _ n0).
move /ltP=>le_n0_n.
move /ltP :le_n0_n.
case/v_scode' => // f [phi [fphi ccl]].
apply: (ex_intro _ f).
apply: conj=>//.
by apply: (can_inj fphi).
Qed.
End variable_length_source_coding.
