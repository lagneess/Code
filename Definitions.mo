/*******************************************************************************
 *
 * Tornado - Advanced Kernel for Modeling and Virtual Experimentation
 * (c) Copyright 2004-2011 DHI
 *
 * This file is provided under the terms of a license and may not be 
 * distributed and/or modified except where allowed by that license.
 *
 * This file is provided as is with no warranty of any kind, including the 
 * warranty of design, merchantability and fitness for a particular purpose.
 *
 * $Revision: 1$
 * $Date: 19. februar 2014 11:18:41$
 *
 ******************************************************************************/

#ifndef __WWTP_ADM1_DEFINITIONS_MO__
#define __WWTP_ADM1_DEFINITIONS_MO__

type TComponents = enumeration
(
S_INN,
S_IC,
S_ch4,
S_h2,
S_aa,
S_ac,
S_bu,
S_fa,
S_Inert,
S_pro,
S_su,
S_va,
X_aa,
X_ac,
X_c,
X_c4,
X_ch,
X_fa,
X_h2,
X_h2_ha,
X_Inert,
X_li,
X_pr,
X_pro,
X_su,
S_an,
S_cat,
S_ch4_gas,
S_co2_gas,
S_h2_gas
) "The biological components considered in the WWTP models" ;


// S_h2 is out !!!
type TComponentsSolubles = enumeration
(
S_INN,
S_IC,
S_ch4,
S_aa,
S_ac,
S_bu,
S_fa,
S_Inert,
S_pro,
S_su,
S_va,
S_an,
S_cat
) "Soluble components" ;


type TComponentsParticulate = enumeration
(
X_aa,
X_ac,
X_c,
X_c4,
X_ch,
X_fa,
X_h2,
X_h2_ha,
X_Inert,
X_li,
X_pr,
X_pro,
X_su
) "Particulate components" ;


// S_h2 is out !!!
type TComponentsInLiquid = enumeration
(
S_INN,
S_IC,
S_ch4,
S_aa,
S_ac,
S_bu,
S_fa,
S_Inert,
S_pro,
S_su,
S_va,
X_aa,
X_ac,
X_c,
X_c4,
X_ch,
X_fa,
X_h2,
X_Inert,
X_li,
X_pr,
X_pro,
X_su,
S_an,
S_cat
) "Components in liquid phase" ;


type TComponentsInGas = enumeration
(
S_ch4_gas,
S_co2_gas,
S_h2_gas
) "Gas components" ;


type TReactions = enumeration
(
decay_aa,
decay_ac,
decay_c4,
decay_fa,
decay_h2,
decay_h2_ha,
decay_pro,
decay_su,
dis,
hyd_ch,
hyd_li,
hyd_pr,
uptake_aa,
uptake_ac,
uptake_bu,
uptake_fa,
uptake_h2,
uptake_h2_ha,
uptake_pro,
uptake_su,
uptake_va,
transfer_ch4,
transfer_co2,
transfer_h2
) "The reactions involving the biological components in the WWTP models" ;


type TReactionsInLiquid = enumeration
(
decay_aa,
decay_ac,
decay_c4,
decay_fa,
decay_h2,
decay_h2_ha,
decay_pro,
decay_su,
dis,
hyd_ch,
hyd_li,
hyd_pr,
uptake_aa,
uptake_ac,
uptake_bu,
uptake_fa,
uptake_h2,
uptake_h2_ha,
uptake_pro,
uptake_su,
uptake_va
) "The reactions in the liquid phase" ;


type TReactionsInGas = enumeration
(
transfer_ch4,
transfer_co2,
transfer_h2
) "The reactions in the gas phase" ;


// ------------------------------------


type TComponentsIons = enumeration
(
S_ac,
S_bu,
S_pro,
S_va,
S_hco3,
S_nh3
) "The ionic components" ;


type TReactionsIons = enumeration
(
dissociation_va,
dissociation_bu,
dissociation_pro,
dissociation_ac,
hco3_co2,
ammonia_production
) "The reactions involving the biological components in the WWTP models" ;

// ------------------------------------
record TWWTPTerminal
  Generic.Quantities.FlowRate Q annotation (group = "Flow rate");
  Real [TComponents] Components annotation (group = "Components");
end TWWTPTerminal ;

/* COULD CONSIDER SEPARATING LIQUID- AND GAS TYPE VECTORS
record TWWTPTerminal
  Generic.Quantities.FlowRate Q annotation (group = "Flow rate");
  Real S_h2 (unit = "") annotation (group = "Components");
  Real [TComponentsInLiquid] Components annotation (group = "Components");
end TWWTPTerminal ;

record TGasTerminal
  Generic.Quantities.FlowRate Q annotation (group = "Flow rate");
  Real [TComponentsInGas] Components annotation (group = "Components");
end TGasTerminal ;
*/

#endif
