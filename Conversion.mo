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
 * $Revision: 2$
 * $Date: 6. marts 2014 16:42:40$
 *
 ******************************************************************************/

#ifndef __WWTP_ADM1_CONVERSION_MO__
#define __WWTP_ADM1_CONVERSION_MO__

// THIS BLOCK SHOULD CLEARLY DISAPPEAR AT A LATER STAGE
block VolumeConstant "..."
  extends ConversionModelBaseADM1;

  initial equation
    
    VLiq = Vol_liq;
    VTot = Vol_gas + Vol_liq;
    
  equation

    der(VLiq) = 0;
    VGas = VTot - VLiq;
    
    Q_Out = Q_In;

    for i in TComponentsInLiquid loop
      Out1.Components[i] = C[i]; // <-- 3 gas species = 0
    end for;
    
    Out1.Components[ADM1.TComponents.S_h2] = C[ADM1.TComponents.S_h2];  // <-- hydrogen
    
    for i in TComponentsInGas loop
      Out3.Components[i] = C[i]; // <-- 3 gas species <> 0
    end for;
    
end VolumeConstant;


// THIS BLOCK SHOULD CLEARLY DISAPPEAR AT A LATER STAGE
partial block WithVolumeADM1
//  extends Ideal1Out;
  
  public
  
    // REMARK: declaration of Input/Output terminals is here because, unlike the corresponding
    // block valid for main category, it does not extend any other "Ideal" type block .
    // Also: the same generic data type is used but the actual component vector is different
    // because it is within the ADM1 package!
    input TWWTPTerminal In "Inflow" annotation (terminal = "in1", group = "Influent");
    output TWWTPTerminal Out1 "Outflow" annotation (terminal = "out1", group = "Effluent");
    output TWWTPTerminal Out3 "Gas flow" annotation (terminal = "out4", group = "Gas flow");

    parameter Real Vol_liq (unit = "m3") = 3400 "Volume of the liquor" annotation (group = "Dimension");
    parameter Real Vol_gas (unit = "m3") = 300 "Headspace volume" annotation (group = "Dimension");

    parameter Real f_X_Out (unit = "-") = 1.0 "Fraction of the anaerobic particulate matter that leaves the reactor" annotation (group = "Operation");

    Real VLiq (unit = "m3", start = 1000) "Volume of the liquor" annotation (favorite = true, group = "Dimension");
    Real VGas (unit = "m3") "Headspace volume" annotation (favorite = true, group = "Dimension");
    Real VTot (unit = "m3") "Reactor volume" annotation (favorite = true, group = "Dimension");

    Quantities.ConcentrationVector C "Concentration" annotation (group = "Concentration");
    Quantities.MolConcentrationVector C_Ion "Concentration" annotation (group = "Concentration");

    Generic.Quantities.FlowRate Q_In "Influent flow rate" annotation (favorite = true, group = "Operation");  
    Generic.Quantities.FlowRate Q_Out "Effluent flow rate" annotation (favorite = true, group = "Operation");
    Generic.Quantities.FlowRate Q_Gas "Gas flow rate" annotation (favorite = true, group = "Operation");
    Generic.Quantities.FlowRate QN_Gas "Normalised gas flow rate" annotation (group = "Operation");
   
  protected
  
    Quantities.MassVector _M (start = {10, 10, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1,
      100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0.1, 10.0,
      10.0, 0.01, 0.01}) "Masses" annotation (group = "Mass");

    Quantities.MassFluxVector FluxPerComponent annotation (group = "_Conversion");
  
  equation
    
    Q_In = In.Q;
    Out1.Q = Q_Out;
    Out3.Q = Q_Gas;
   
    // Concentration vector
    for i in TComponentsInLiquid loop
      C[i] = if (abs(VLiq) <= 1e-008) then 0.0 else (_M[i] / VLiq); 
    end for;
    
    for i in TComponentsInGas loop
      C[i] = if (abs(VGas) <= 1e-008) then 0.0 else (_M[i] / VGas); 
    end for;

    C[ADM1.TComponents.S_h2] = C_H2;  // <-- hydrogen

    // Fluxes
    for i in TComponentsSolubles loop
      FluxPerComponent[i] = (In.Q * In.Components[i]) - (Out1.Q * Out1.Components[i]); 
    end for;

    for i in TComponentsParticulate loop
      FluxPerComponent[i] = (In.Q * In.Components[i]) - (f_X_Out * Out1.Q * Out1.Components[i]); 
    end for;

    for i in TComponentsInGas loop
      FluxPerComponent[i] = (In.Q * In.Components[i]) - (Out3.Q * Out3.Components[i]); 
    end for;
  
end WithVolumeADM1;

// ------------------------------------------

partial block ConversionModelBaseADM1
  extends WithVolumeADM1;

  // consider: import Generic.Quantities.*;
  import Generic.Quantities.pH;
  import Generic.Quantities.MolConcentration;
  import Generic.Quantities.DecayCoefficient;
  import Generic.Quantities.CelsiusTemperature;
  import Generic.Quantities.OxygenTransferCoefficient;

  public  
  
    input CelsiusTemperature T_op = 35 "Temperature" annotation (terminal = "in2", manip = true, group = "Operation");

    // Carbon content
    parameter Real C_aa (unit = "mol/gCOD") = 0.03 "Carbon content of amino acids" annotation (group = "Stoichiometry");
    parameter Real C_pr (unit = "mol/gCOD") = 0.03 "Carbon content of proteines" annotation (group = "Stoichiometry");
    parameter Real C_ac (unit = "mol/gCOD") = 0.0313 "Carbon content of acetate" annotation (group = "Stoichiometry");
    parameter Real C_biom (unit = "mol/gCOD") = 0.0313 "Carbon content of biomass" annotation (group = "Stoichiometry");
    parameter Real C_bu (unit = "mol/gCOD") = 0.025 "Carbon content of butyrate" annotation (group = "Stoichiometry");
    parameter Real C_ch4 (unit = "mol/gCOD") = 0.0156 "Carbon content of methane" annotation (group = "Stoichiometry");
    parameter Real C_fa (unit = "mol/gCOD") = 0.0217 "Carbon content of long chain fatty acids" annotation (group = "Stoichiometry");
    parameter Real C_li (unit = "mol/gCOD") = 0.022 "Carbon content of lipids" annotation (group = "Stoichiometry");
    parameter Real C_pro (unit = "mol/gCOD") = 0.0268 "Carbon content of propionate" annotation (group = "Stoichiometry");
    parameter Real C_SI (unit = "mol/gCOD") = 0.03 "Carbon content of soluble inert COD" annotation (group = "Stoichiometry");
    parameter Real C_su (unit = "mol/gCOD") = 0.0313 "Carbon content of sugars" annotation (group = "Stoichiometry");
    parameter Real C_ch (unit = "mol/gCOD") = 0.0313 "Carbon content of carbohydrates" annotation (group = "Stoichiometry");
    parameter Real C_va (unit = "mol/gCOD") = 0.024 "Carbon content of valerate" annotation (group = "Stoichiometry");
    parameter Real C_Xc (unit = "mol/gCOD") = 0.02786 "Carbon content of complex particulate COD" annotation (group = "Stoichiometry");
    parameter Real C_XI (unit = "mol/gCOD") = 0.03 "Carbon content of particulate inert COD" annotation (group = "Stoichiometry");

    // Nitrogen content
    parameter Real N_aa (unit = "mol/gCOD") = 0.007 "Nitrogen content of amino acids" annotation (group = "Stoichiometry");
    parameter Real N_biom (unit = "mol/gCOD") = 0.00571428571428571 "Nitrogen content of  biomass" annotation (group = "Stoichiometry");
    parameter Real N_SI (unit = "mol/gCOD") = 0.00428571428571429 "Nitrogen content of soluble inert COD" annotation (group = "Stoichiometry");
    parameter Real N_Xc (unit = "mol/gCOD") = 0.00268571428571429 "Nitrogen content of particulate degradable COD" annotation (group = "Stoichiometry");
    parameter Real N_XI (unit = "mol/gCOD") = 0.00428571428571429 "Nitrogen content of particulate inert COD" annotation (group = "Stoichiometry");

    // pre-set fractions and yields
    parameter Real f_ac_su (unit = "-") = 0.41 "Yield of acetate from sugar degradation" annotation (group = "Stoichiometry");
    parameter Real f_ac_aa (unit = "-") = 0.4 "Yield of acetate from amino acid degradation" annotation (group = "Stoichiometry");
    parameter Real f_bu_aa (unit = "-") = 0.26 "Yield of butyrate from amino acid degradation" annotation (group = "Stoichiometry");
    parameter Real f_ch_xc (unit = "-") = 0.2 "Yield of carbohydrates from disintegration of complex particulates" annotation (group = "Stoichiometry");
    parameter Real f_fa_li (unit = "-") = 0.95 "Yield of long chain fatty acids (as opposed to glycerol) from lipids" annotation (group = "Stoichiometry");
    parameter Real f_h2_aa (unit = "-") = 0.06 "Yield of hydrogen from amino acid degradation" annotation (group = "Stoichiometry");
    parameter Real f_pro_aa (unit = "-") = 0.05 "Yield of propionate from amino acid degradation" annotation (group = "Stoichiometry");
    parameter Real f_pro_su (unit = "-") = 0.27 "Yield of propionate from monosaccharide degradation" annotation (group = "Stoichiometry");
    parameter Real f_pr_xc (unit = "-") = 0.2 "Yield of proteins from disintegration of complex particulates" annotation (group = "Stoichiometry");
    parameter Real f_SI_xc (unit = "-") = 0.1 "Yield of soluble inerts from disintegration of complex particulates" annotation (group = "Stoichiometry");
    parameter Real f_va_aa (unit = "-") = 0.23 "Yield of valerate from amino acid degradation" annotation (group = "Stoichiometry");
    parameter Real f_XI_xc (unit = "-") = 0.2 "Yield of particulate inerts from disintegration of complex particulates" annotation (group = "Stoichiometry");
    parameter Real f_bu_su (unit = "-") = 0.13 "Yield of butyrate from monosaccharide degradation" annotation (group = "Stoichiometry");
    parameter Real f_h2_su (unit = "-") = 0.19 "Yield of hydrogen from monosaccharide degradation" annotation (group = "Stoichiometry");
    parameter Real f_li_xc (unit = "-") = 0.3 "Yield of lipids from disintegration of complex particulates" annotation (group = "Stoichiometry");

    // biomass yields 
    parameter Real Y_aa (unit = "-") = 0.08 "Yield of biomass on uptake of amino acids" annotation (group = "Stoichiometry");
    parameter Real Y_ac (unit = "-") = 0.05 "Yield of biomass on uptake of acetate" annotation (group = "Stoichiometry");
    parameter Real Y_c4 (unit = "-") = 0.06 "Yield of biomass on uptake of valerate or butyrate" annotation (group = "Stoichiometry");
    parameter Real Y_fa (unit = "-") = 0.06 "Yield of biomass on uptake of long chain fatty acids" annotation (group = "Stoichiometry");
    parameter Real Y_h2 (unit = "-") = 0.06 "Yield of biomass on uptake of elemental hydrogen" annotation (group = "Stoichiometry");
    parameter Real Y_pro (unit = "-") = 0.04 "Yield of biomass on uptake of propionate" annotation (group = "Stoichiometry");
    parameter Real Y_su (unit = "-") = 0.1 "Yield of biomass on uptake of monosaccharides" annotation (group = "Stoichiometry");

    // pH inhibitory/not levels
    parameter pH pH_ac_ll = 6.0 "pH level at which there is full inhibition of acetate degradation" annotation (group = "Kinetics");
    parameter pH pH_ac_ul = 7.0 "pH level at which there is no inhibition of acetate degrading organisms" annotation (group = "Kinetics");
    parameter pH pH_bac_ll = 4.0 "pH level at which there is full inhibition" annotation (group = "Kinetics");
    parameter pH pH_bac_ul = 5.5 "pH level at which there is no inhibition" annotation (group = "Kinetics");
    parameter pH pH_h2_ll = 5.0 "pH level at which there is full inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");
    parameter pH pH_h2_ul = 6.0 "pH level at which there is no inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");

    // Ka values default are defined at 308.15k 
    parameter MolConcentration Ka_ac = 1.74e-5 "Acetate acidity constant (temperature correction can be ignored)" annotation (group = "Stoichiometry"); 
    parameter MolConcentration Ka_bu = 1.51e-5 "Butyrate acidity constant (temperature correction can be ignored)" annotation (group = "Stoichiometry");
    parameter MolConcentration Ka_co2 = 4.94e-7 "CO2 acidity constant (temperature correction needed)" annotation (group = "Stoichiometry");
    parameter MolConcentration Ka_h2o = 2.08e-14 "Water acidity constant (temperature correction needed)" annotation (group = "Stoichiometry");
    parameter MolConcentration Ka_nh4 = 1.11e-9 "NH4+ acidity constant (temperature correction needed)" annotation (group = "Stoichiometry");
    parameter MolConcentration Ka_pro = 1.32e-5 "Propionate acidity constant (temperature correction can be ignored)" annotation (group = "Stoichiometry");
    parameter MolConcentration Ka_va = 1.38e-5 "Valerate acidity constant (temperature correction can be ignored)" annotation (group = "Stoichiometry");

    // hydrogen inhibitory concentration
    parameter Real KI_h2_fa (unit = "kg/m3") = 5E-006 "Hydrogen inhibitory concentration for FA degrading organisms" annotation (group = "Kinetics");
    parameter Real KI_h2_c4 (unit = "kg/m3") = 1E-005 "Hydrogen inhibitory concentration for C4 degrading organisms" annotation (group = "Kinetics");
    parameter Real KI_h2_pro (unit = "kg/m3") = 3.5E-006 "Inhibitory hydrogen concentration for propionate degrading organisms" annotation (group = "Kinetics");
    parameter Real KI_nh3_ac (unit = "kg/m3") = 0.0018 "Inhibitory free ammonia concentration for acetate degrading organisms" annotation (group = "Kinetics");

    //  decay and disintegration
    parameter DecayCoefficient kdec_xaa = 0.02 "Decay rate for amino acid degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xac = 0.02 "Decay rate for acetate degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xc4 = 0.02 "Decay rate for butyrate and valerate degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xfa = 0.02 "Decay rate for long chain fatty acid degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xh2 = 0.02 "Decay rate for hydrogen degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xpro = 0.02 "Decay rate for propionate degrading organisms" annotation (group = "Kinetics");
    parameter DecayCoefficient kdec_xsu = 0.02 "Decay rate for monosaccharide degrading organisms" annotation (group = "Kinetics");
    parameter Real kdis (unit = "1/d") = 0.5 "Complex particulate disintegration first order rate constant" annotation (group = "Kinetics");

    //  hydrolysis rates
    parameter Real khyd_ch (unit = "1/d") = 10.0 "Carbohydrate hydrolysis first order rate constant" annotation (group = "Kinetics");
    parameter Real khyd_li (unit = "1/d") = 10.0 "Lipid hydrolysis first order rate constant" annotation (group = "Kinetics");
    parameter Real khyd_pr (unit = "1/d") = 10.0 "Protein hydrolysis first order rate constant" annotation (group = "Kinetics");

    //  gas transfer rate
    parameter OxygenTransferCoefficient kLa = 200.0 "Gas/Liquid transfer coefficient" annotation (group = "Operation");

    //  uptake rates
    parameter Real km_aa (unit = "1/d") = 50.0 "Maximum uptake rate amino acid degrading organisms" annotation (group = "Kinetics");
    parameter Real km_ac (unit = "1/d") = 8.0 "Maximum uptake rate for acetate degrading organisms" annotation (group = "Kinetics");
    parameter Real km_c4 (unit = "1/d") = 20.0 "Maximum uptake rate for c4 degrading organisms" annotation (group = "Kinetics");
    parameter Real km_fa (unit = "1/d") = 6.0 "Maximum uptake rate for long chain fatty acid degrading organisms" annotation (group = "Kinetics");
    parameter Real km_h2 (unit = "1/d") = 35.0 "Maximum uptake rate for hydrogen degrading organisms" annotation (group = "Kinetics");
    parameter Real km_pro (unit = "1/d") = 13.0 "Maximum uptake rate for propionate degrading organisms" annotation (group = "Kinetics");
    parameter Real km_su (unit = "1/d") = 30.0 "Maximum uptake rate for monosaccharide degrading organisms" annotation (group = "Kinetics");
    parameter Real Ks_aa (unit = "kg/m3") = 0.3 "Half saturation constant for amino acid degradation" annotation (group = "Kinetics");
    parameter Real Ks_ac (unit = "kg/m3") = 0.15 "Half saturation constant for acetate degradation" annotation (group = "Kinetics");
    parameter Real Ks_c4 (unit = "kg/m3") = 0.2 "Half saturation constant for butyrate and valerate degradation" annotation (group = "Kinetics");
    parameter Real Ks_fa (unit = "kg/m3") = 0.4 "Half saturation constant for long chain fatty acids degradation" annotation (group = "Kinetics");
    parameter Real Ks_h2 (unit = "kg/m3") = 7E-006 "Half saturation constant for uptake of hydrogen" annotation (group = "Kinetics");
    parameter Real Ks_pro (unit = "kg/m3") = 0.1 "Half saturation constant for propionate degradation" annotation (group = "Kinetics");
    parameter Real Ks_su (unit = "kg/m3") = 0.5 "Half saturation constant for monosaccharide degradation" annotation (group = "Kinetics");
    parameter MolConcentration Ks_IN = 0.0001 "Inorganic nitrogen concentration at which growth ceases" annotation (group = "Kinetics");
    parameter Real K_p (unit = "-") = 5e4 "Inorganic nitrogen concentration at which growth ceases" annotation (group = "Kinetics");
    parameter Real P_atm (unit = "bar") = 1.013 "Atmospheric pressure" annotation (group = "Operation");

    CelsiusTemperature Temp_Actual "Temperature" annotation (group = "Operation");

    // <-- is the unit (g/m3) correct even though the rest of the model is in kg/m3 ???
    Real C_H2 (unit = "g/m3") "Hydrogen concentration" annotation (group = "Concentration");

    // REMARK!!! these are not unitless: check!
    Real KH_ch4 (unit = "-") "Henry's law constant (T-dep) for CH4 with temperature correction" annotation (group = "Kinetics");
    Real KH_co2 (unit = "-") "Henry's law constant (T-dep) for CO2 with temperature correction" annotation (group = "Kinetics");
    Real KH_h2 (unit = "-") "Henry's law constant (T-dep) for H2 with temperature correction" annotation (group = "Kinetics");

    Real I_h2_fa (unit = "-") "Hydrogen inhibition for LCFA degradation" annotation (group = "Kinetics");
    Real I_h2_c4 (unit = "-") "Hydrogen inhibition for C4+ degradation" annotation (group = "Kinetics");
    Real I_h2_pro (unit = "-") "Hydrogen inhibition for propionate" annotation (group = "Kinetics");
    Real I_nh3_ac (unit = "-") "NH3 inhibition of acetoclastic methanogenesis" annotation (group = "Kinetics");
    Real I_NH_limit (unit = "-") "Function to limit growth due to lack of inorganic nitrogen" annotation (group = "Kinetics");
    Real I_pH_ac (unit = "-") "pH inhibition of acetate degrading organisms" annotation (group = "Kinetics");
    Real I_pH_bac (unit = "-") "pH inhibition of acetogens and acidogens" annotation (group = "Kinetics");  // <-- (lower inhibition only used here)
    Real I_pH_h2 (unit = "-") "pH inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");

    pH _pH "pH" annotation (group = "Operation");

    Real Ka_in (unit = "-") "Inorganic nitrogen acidity constant" annotation (group = "System");
    Real Ka_ic (unit = "-") "Inorganic carbon acidity constant" annotation (group = "System");
    Real Kw (unit = "-") "Water acidity constant" annotation (group = "System");

    Real p_CH4 (unit = "bar") "Partial pressure of ch4" annotation (group = "Operation");
    Real p_CO2 (unit = "bar") "Partial pressure of co2" annotation (group = "Operation");
    Real p_H2 (unit = "bar") "Partial pressure of h2" annotation (group = "Operation");
    Real P_Headspace (unit = "bar") "Total gas phase pressure" annotation (group = "Operation");
    Real p_H2O (unit = "bar") "Partial pressure of water" annotation (group = "Operation");

    Real S_CO2 (unit = "mol/m3") "Carbon dioxide" annotation (group = "Concentration");
    Real S_NH4_ion (unit = "mol/m3") "Ammonium ion" annotation (group = "Concentration");
    Real S_H_ion (unit = "mol/m3") "Hydrogen ion" annotation (group = "Concentration");
    Real charge_balance (unit = "-") "Left hand-side of charge balance" annotation (group = "Concentration");

  protected
  
    constant Real R_Gas (unit = "J/mol/K") = Generic.Constants.UniversalGasConstant annotation (group = "Constants");
    parameter Quantities.StoichiometryMatrix Stoichiometry "Body of the Gujer Matrix" annotation (group = "_Stoichiometry");
    Quantities.ConversionTermVector ConversionTermPerComponent "Vector of conversion rates" annotation (group = "_Conversion");
    Quantities.KineticVector Kinetics "Rate column of the Gujer Matrix" annotation (group = "_Kinetics");
    Real _TK (unit = "K") "Absolute temperature" annotation (group = "_Stoichiometry");
    // other state variables needed in the calculation
    Real balance_COD_S (unit = "kg/m3") "Total COD of soluble substrate" annotation (group = "_Continuity");
    Real balance_COD_X (unit = "kg/m3") "Total COD of particulate substrate" annotation (group = "_Continuity");
    Real pHLim_ac (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");
    Real pHLim_bac (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");
    Real pHLim_h2 (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");
    Real n_ac (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");
    Real n_bac (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");
    Real n_h2 (unit = "-") "state needed in Hill function" annotation (group = "_Kinetics");

  initial equation
     
    // process 1: decay of amino acid degrading organisms
    Stoichiometry[ADM1.TReactions.decay_aa, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_aa, ADM1.TComponents.X_aa] = -1;
    Stoichiometry[ADM1.TReactions.decay_aa, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_aa, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 2: decay of acetate degrading organisms
    Stoichiometry[ADM1.TReactions.decay_ac, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_ac, ADM1.TComponents.X_ac] = -1;
    Stoichiometry[ADM1.TReactions.decay_ac, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_ac, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 3: decay of butyrate and valerate degrading organisms
    Stoichiometry[ADM1.TReactions.decay_c4, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_c4, ADM1.TComponents.X_c4] = -1;
    Stoichiometry[ADM1.TReactions.decay_c4, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_c4, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 4: decay of LCFA degrading organisms
    Stoichiometry[ADM1.TReactions.decay_fa, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_fa, ADM1.TComponents.X_fa] = -1;
    Stoichiometry[ADM1.TReactions.decay_fa, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_fa, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 5: decay of hydrogen degrading organisms
    Stoichiometry[ADM1.TReactions.decay_h2, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_h2, ADM1.TComponents.X_h2] = -1;
    Stoichiometry[ADM1.TReactions.decay_h2, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_h2, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 6: decay of propionate degrading organisms
    Stoichiometry[ADM1.TReactions.decay_pro, ADM1.TComponents.X_pro] = -1;
    Stoichiometry[ADM1.TReactions.decay_pro, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_pro, ADM1.TComponents.S_IC] = C_biom - C_Xc;
    Stoichiometry[ADM1.TReactions.decay_pro, ADM1.TComponents.S_INN] = N_biom - N_Xc;
    // process 7: decay of monosaccharide degrading organisms
    Stoichiometry[ADM1.TReactions.decay_su, ADM1.TComponents.X_su] = -1;
    Stoichiometry[ADM1.TReactions.decay_su, ADM1.TComponents.X_c] = 1;
    Stoichiometry[ADM1.TReactions.decay_su, ADM1.TComponents.S_IC] = C_biom -C_Xc;
    Stoichiometry[ADM1.TReactions.decay_su, ADM1.TComponents.S_INN] = N_biom -N_Xc;
    // process 8: first order disintegration of complex particulates
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.X_c] = -1;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.X_ch] = f_ch_xc;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.X_pr] = f_pr_xc;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.X_Inert] = f_XI_xc;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.X_li] = f_li_xc;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.S_Inert] = f_SI_xc;  
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.S_IC] = C_Xc - f_ch_xc * C_ch - f_SI_xc * C_SI - f_pr_xc * C_pr -  f_XI_xc * C_XI - f_li_xc * C_li;
    Stoichiometry[ADM1.TReactions.dis, ADM1.TComponents.S_INN] = N_Xc -f_XI_xc * N_XI -f_SI_xc * N_SI -f_pr_xc * N_aa;
    // process 9: first order hydrolysis of carbohydrates
    Stoichiometry[ADM1.TReactions.hyd_ch, ADM1.TComponents.S_su] = 1;
    Stoichiometry[ADM1.TReactions.hyd_ch, ADM1.TComponents.X_ch] = -1;
    Stoichiometry[ADM1.TReactions.hyd_ch, ADM1.TComponents.S_IC] = C_ch - C_su;
    // process 10: first order hydrolysis of lipids
    Stoichiometry[ADM1.TReactions.hyd_li, ADM1.TComponents.S_su] = 1 -f_fa_li;
    Stoichiometry[ADM1.TReactions.hyd_li, ADM1.TComponents.S_fa] = f_fa_li;
    Stoichiometry[ADM1.TReactions.hyd_li, ADM1.TComponents.X_li] = -1;
    Stoichiometry[ADM1.TReactions.hyd_li, ADM1.TComponents.S_IC] = (f_fa_li - 1) * C_su - f_fa_li * C_fa + C_li;
    // process 11: first order hydrolysis of proteins
    Stoichiometry[ADM1.TReactions.hyd_pr, ADM1.TComponents.S_aa] = 1;
    Stoichiometry[ADM1.TReactions.hyd_pr, ADM1.TComponents.X_pr] = -1;
    Stoichiometry[ADM1.TReactions.hyd_pr, ADM1.TComponents.S_IC] = C_aa - C_pr;
    // process 12: uptake of amino acids
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_h2] = (1-Y_aa)*f_h2_aa;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_IC] = C_aa - (1-Y_aa) * f_ac_aa * C_ac - (1-Y_aa) * f_bu_aa * C_bu -(1 -Y_aa) * f_pro_aa * C_pro -(1-Y_aa) * f_va_aa * C_va - Y_aa * C_biom;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_ac] = (1-Y_aa) * f_ac_aa;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_bu] = (1-Y_aa) * f_bu_aa;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_aa] = -1;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_pro] = (1-Y_aa) * f_pro_aa;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_va] = (1-Y_aa) * f_va_aa;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.S_INN] = N_aa -Y_aa * N_biom;
    Stoichiometry[ADM1.TReactions.uptake_aa, ADM1.TComponents.X_aa] = Y_aa;
    // process 13: uptake of acetate
    Stoichiometry[ADM1.TReactions.uptake_ac, ADM1.TComponents.S_ac] = -1;
    Stoichiometry[ADM1.TReactions.uptake_ac, ADM1.TComponents.X_ac] = Y_ac;
    Stoichiometry[ADM1.TReactions.uptake_ac, ADM1.TComponents.S_INN] = -N_biom * Y_ac;
    Stoichiometry[ADM1.TReactions.uptake_ac, ADM1.TComponents.S_ch4] =1-Y_ac;
    Stoichiometry[ADM1.TReactions.uptake_ac, ADM1.TComponents.S_IC] = C_ac -Y_ac * C_biom -(1-Y_ac) * C_ch4;
    // process 14: uptake of butyrate
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.S_h2] = (1 -Y_c4 )*0.2;
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.S_ac] = (1 -Y_c4 )*0.8;
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.X_c4] = Y_c4;
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.S_INN] = -N_biom * Y_c4;
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.S_bu] = -1;
    Stoichiometry[ADM1.TReactions.uptake_bu, ADM1.TComponents.S_IC] = C_bu - (1 -Y_c4 )* 0.8 * C_ac - Y_c4 * C_biom;
    // process 15: uptake of LCFA
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.S_h2] = (1-Y_fa)*0.3;
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.S_ac] = (1-Y_fa)*0.7;
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.X_fa] = Y_fa;
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.S_INN] = -N_biom * Y_fa;
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.S_fa] = -1;
    Stoichiometry[ADM1.TReactions.uptake_fa, ADM1.TComponents.S_IC] = C_fa - (1-Y_fa) * 0.7 * C_ac - Y_fa * C_biom;
    // process 16: uptake of h2
    Stoichiometry[ADM1.TReactions.uptake_h2, ADM1.TComponents.S_h2] = -1;
    Stoichiometry[ADM1.TReactions.uptake_h2, ADM1.TComponents.X_h2] = Y_h2;
    Stoichiometry[ADM1.TReactions.uptake_h2, ADM1.TComponents.S_INN] = -N_biom * Y_h2;
    Stoichiometry[ADM1.TReactions.uptake_h2, ADM1.TComponents.S_ch4] = 1 -Y_h2;
    Stoichiometry[ADM1.TReactions.uptake_h2, ADM1.TComponents.S_IC] = -Y_h2 * C_biom - (1 -Y_h2) * C_ch4;
    // process 17: uptake of propionate
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.S_h2] = (1-Y_pro)*0.43;
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.S_ac] = (1-Y_pro)*0.57;
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.X_pro] = Y_pro;
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.S_INN] = -N_biom * Y_pro;
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.S_pro] = -1;
    Stoichiometry[ADM1.TReactions.uptake_pro, ADM1.TComponents.S_IC] = C_pro -(1 -Y_pro) * 0.57 * C_ac -Y_pro * C_biom;
    // process 18: uptake of monosaccharides
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_h2] = (1-Y_su) * f_h2_su;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_IC] = C_su -(1 - Y_su) * f_ac_su * C_ac -(1 -Y_su) * f_pro_su * C_pro -(1 -Y_su) * f_bu_su * C_bu -Y_su * C_biom;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_ac] = (1 -Y_su) * f_ac_su;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.X_su] = Y_su;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_INN] = -N_biom * Y_su;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_su] = -1;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_bu] = (1-Y_su) * f_bu_su;
    Stoichiometry[ADM1.TReactions.uptake_su, ADM1.TComponents.S_pro] = (1-Y_su) * f_pro_su;
    // process 19: uptake of valerate
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_h2] = (1-Y_c4)*0.15;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_ac] = (1-Y_c4)*0.31;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.X_c4] = Y_c4;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_INN] = -N_biom * Y_c4;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_va] = -1;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_pro] = (1-Y_c4)*0.54;
    Stoichiometry[ADM1.TReactions.uptake_va, ADM1.TComponents.S_IC] = C_va - (1-Y_c4)*0.54 * C_pro - Y_c4 * C_biom - (1-Y_c4) * 0.31 * C_ac;
    // Processes 20-26 are reserved for updating to the DE implementation if needed.
    // process 27: transfer of CO2
    Stoichiometry[ADM1.TReactions.transfer_co2, ADM1.TComponents.S_IC] = -1;
    Stoichiometry[ADM1.TReactions.transfer_co2, ADM1.TComponents.S_co2_gas] = 1;
    // process 28: transfere of H2
    Stoichiometry[ADM1.TReactions.transfer_h2, ADM1.TComponents.S_h2] = -1;
    Stoichiometry[ADM1.TReactions.transfer_h2, ADM1.TComponents.S_h2_gas] = 1; 
    // process 29: transfer of CH4
    Stoichiometry[ADM1.TReactions.transfer_ch4, ADM1.TComponents.S_ch4] = -1;
    Stoichiometry[ADM1.TReactions.transfer_ch4, ADM1.TComponents.S_ch4_gas] = 1;

  equation
  
    _TK = Temp_Actual + 273.15;
    Temp_Actual = T_op;

    // preliminary calculations for the inhibitions
    I_h2_fa = 1 / (C_H2 / KI_h2_fa + 1);
    I_h2_c4 = 1 / (C_H2 / KI_h2_c4 + 1); 
    I_h2_pro = 1 / (C_H2 / KI_h2_pro + 1);
    I_nh3_ac = 1 / (C_Ion[ADM1.TComponentsIons.S_nh3] / KI_nh3_ac + 1);
    I_NH_limit = if (abs(C[ADM1.TComponents.S_INN]) <= 1e-008) then 0.0 else (1 / (Ks_IN / C[ADM1.TComponents.S_INN] + 1));

    // Hill functions on SH+ for calculation of inhibition terms
    pHLim_ac = pow(10,(-(pH_ac_ul + pH_ac_ll) / 2.0));
    pHLim_bac = pow(10,(-(pH_bac_ul + pH_bac_ll) / 2.0));
    pHLim_h2 = pow(10,(-(pH_h2_ul + pH_h2_ll) / 2.0));
    n_ac = 3.0 / (pH_ac_ul - pH_ac_ll);
    n_bac = 3.0 / (pH_bac_ul - pH_bac_ll);
    n_h2 = 3.0 / (pH_h2_ul - pH_h2_ll);
    I_pH_ac = pow(pHLim_ac, n_ac) / (pow(S_H_ion, n_ac) + pow(pHLim_ac, n_ac));
    I_pH_bac = pow(pHLim_bac, n_bac) / (pow(S_H_ion, n_bac) + pow(pHLim_bac, n_bac));
    I_pH_h2 = pow(pHLim_h2, n_h2) / (pow(S_H_ion, n_h2) + pow(pHLim_h2, n_h2));

    // Kinetic equations
    Kinetics[ADM1.TReactions.decay_aa] = kdec_xaa * C[ADM1.TComponents.X_aa];
    Kinetics[ADM1.TReactions.decay_ac] = kdec_xac * C[ADM1.TComponents.X_ac];
    Kinetics[ADM1.TReactions.decay_c4] = kdec_xc4 * C[ADM1.TComponents.X_c4];
    Kinetics[ADM1.TReactions.decay_fa] = kdec_xfa * C[ADM1.TComponents.X_fa];
    Kinetics[ADM1.TReactions.decay_h2] = kdec_xh2 * C[ADM1.TComponents.X_h2];
    Kinetics[ADM1.TReactions.decay_pro] = kdec_xpro * C[ADM1.TComponents.X_pro];
    Kinetics[ADM1.TReactions.decay_su] = kdec_xsu * C[ADM1.TComponents.X_su];
    Kinetics[ADM1.TReactions.dis] = kdis * C[ADM1.TComponents.X_c];
    Kinetics[ADM1.TReactions.hyd_ch] = khyd_ch * C[ADM1.TComponents.X_ch];
    Kinetics[ADM1.TReactions.hyd_li] = khyd_li * C[ADM1.TComponents.X_li];
    Kinetics[ADM1.TReactions.hyd_pr] = khyd_pr * C[ADM1.TComponents.X_pr];
    Kinetics[ADM1.TReactions.uptake_aa] = km_aa * C[ADM1.TComponents.X_aa] * C[ADM1.TComponents.S_aa] /(Ks_aa + C[ADM1.TComponents.S_aa]) * I_pH_bac * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_ac] = km_ac * C[ADM1.TComponents.X_ac] * C[ADM1.TComponents.S_ac] / (Ks_ac + C[ADM1.TComponents.S_ac]) * I_pH_ac * I_nh3_ac * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_bu] = km_c4 * C[ADM1.TComponents.X_c4] * C[ADM1.TComponents.S_bu] / (Ks_c4 + C[ADM1.TComponents.S_bu]) * C[ADM1.TComponents.S_bu] / (C[ADM1.TComponents.S_bu] + C[ADM1.TComponents.S_va] + 0.000001) * I_pH_bac * I_h2_c4 * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_fa] = km_fa * C[ADM1.TComponents.X_fa] * C[ADM1.TComponents.S_fa] / (Ks_fa + C[ADM1.TComponents.S_fa]) * I_pH_bac * I_h2_fa * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_h2] = km_h2 * C[ADM1.TComponents.X_h2] * C_H2 / (Ks_h2 + C_H2) * I_pH_h2 * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_pro] = km_pro * C[ADM1.TComponents.X_pro] * C[ADM1.TComponents.S_pro] / (Ks_pro + C[ADM1.TComponents.S_pro]) * I_pH_bac * I_h2_pro * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_su] = km_su * C[ADM1.TComponents.X_su] * C[ADM1.TComponents.S_su] / (Ks_su + C[ADM1.TComponents.S_su]) * I_pH_bac * I_NH_limit;
    Kinetics[ADM1.TReactions.uptake_va] = km_c4 * C[ADM1.TComponents.X_c4] * C[ADM1.TComponents.S_va] / (Ks_c4 + C[ADM1.TComponents.S_va]) * C[ADM1.TComponents.S_va] / (C[ADM1.TComponents.S_va] + C[ADM1.TComponents.S_bu] + 0.000001) * I_pH_bac * I_h2_c4 * I_NH_limit;
    Kinetics[ADM1.TReactions.transfer_ch4] = kLa * (C[ADM1.TComponents.S_ch4] -  KH_ch4 * C[ADM1.TComponents.S_ch4_gas] * (R_Gas / 100) * _TK );
    Kinetics[ADM1.TReactions.transfer_co2] = kLa * (S_CO2 -  KH_co2 * C[ADM1.TComponents.S_co2_gas] * (R_Gas / 100) * _TK );
    Kinetics[ADM1.TReactions.transfer_h2] = kLa * (C_H2 -  KH_h2 * C[ADM1.TComponents.S_h2_gas] * (R_Gas / 100) * _TK );
    
    //Calculation of T-dependent Henry constants
    KH_co2 = 0.035 * exp(-19410 / R_Gas * ((1/308.15) - (1 / _TK)));
    KH_h2 = 7.8e-4 * exp(-4180 / R_Gas * ((1/308.15) - (1 / _TK)));
    KH_ch4 = 0.0014 * exp(-14240 / R_Gas * ((1/308.15) - (1 / _TK)));

    //Updates for ion and pH calculation using external functions 
    Ka_in = pow(10,-9.25) * (exp(51965 * ((1/308.15) - (1 / _TK)) / R_Gas));   
    Ka_ic = pow(10,-6.35) * (exp(7646 * ((1/308.15) - (1 / _TK)) / R_Gas));
    Kw = pow(10,-14) * (exp(55900 * ((1/308.15) - (1 / _TK)) / R_Gas));

    S_CO2 = (C[ADM1.TComponents.S_IC] - C_Ion[ADM1.TComponentsIons.S_hco3]);
    S_NH4_ion = ADM1.pH.NH_Ion(Ka_in,C[ADM1.TComponents.S_INN],S_H_ion);
    S_H_ion = ADM1.pH.Compute(Ka_in, Ka_ic, Ka_ac, Ka_bu, Ka_va, Ka_pro, Kw, C[ADM1.TComponents.S_INN],
      C[ADM1.TComponents.S_IC], C[ADM1.TComponents.S_ac], C[ADM1.TComponents.S_bu], C[ADM1.TComponents.S_va],
      C[ADM1.TComponents.S_pro], C[ADM1.TComponents.S_cat], C[ADM1.TComponents.S_an], previous(S_H_ion));
    C_Ion[ADM1.TComponentsIons.S_nh3] = (C[ADM1.TComponents.S_INN] - S_NH4_ion);
    C_Ion[ADM1.TComponentsIons.S_hco3] = ADM1.pH.HCO_Ion(Ka_ic, C[ADM1.TComponents.S_IC], S_H_ion);
    C_Ion[ADM1.TComponentsIons.S_ac] = ADM1.pH.Ac_Ion(Ka_ac, C[ADM1.TComponents.S_ac], S_H_ion);
    C_Ion[ADM1.TComponentsIons.S_pro] = ADM1.pH.Pro_Ion(Ka_pro, C[ADM1.TComponents.S_pro], S_H_ion);
    C_Ion[ADM1.TComponentsIons.S_bu] = ADM1.pH.Bu_Ion(Ka_bu, C[ADM1.TComponents.S_bu], S_H_ion);
    C_Ion[ADM1.TComponentsIons.S_va] = ADM1.pH.Va_Ion(Ka_va, C[ADM1.TComponents.S_va], S_H_ion);
  
    _pH = -log10(S_H_ion);
    //charge balance
    charge_balance = S_H_ion + C[ADM1.TComponents.S_cat] + S_NH4_ion - C[ADM1.TComponents.S_an] -
      Kw/S_H_ion - C_Ion[ADM1.TComponentsIons.S_hco3] - C_Ion[ADM1.TComponentsIons.S_ac] / 64.0 -
      C_Ion[ADM1.TComponentsIons.S_pro] / 112.0 - C_Ion[ADM1.TComponentsIons.S_bu] / 160.0 -
      C_Ion[ADM1.TComponentsIons.S_va] / 208.0;

    // CONVERSION TERMS
    // This may be not valid for S_h2 - but since it is not used for S_h2 anywhere, can leave it
    // Check again if ComponentsIons will be added to Main Components vector
    ConversionTermPerComponent = VLiq * (Kinetics * Stoichiometry);

    C_H2 = ADM1.h2.Compute(Q_In, VLiq, In.Components[ADM1.TComponents.S_h2], previous(C_H2), Y_su,
      f_h2_su, Kinetics[ADM1.TReactions.uptake_su], Y_aa, f_h2_aa, Kinetics[ADM1.TReactions.uptake_aa], Y_fa,
      km_fa, C[ADM1.TComponents.S_fa], Ks_fa, C[ADM1.TComponents.X_fa], I_pH_bac, I_NH_limit, KI_h2_fa, Y_c4, km_c4,
      C[ADM1.TComponents.S_va], Ks_c4, C[ADM1.TComponents.X_c4], C[ADM1.TComponents.S_bu], KI_h2_c4, Y_pro, km_pro,
      C[ADM1.TComponents.S_pro], Ks_pro, C[ADM1.TComponents.X_pro], KI_h2_pro, km_h2, Ks_h2, C[ADM1.TComponents.X_h2],
      I_pH_h2, kLa, KH_h2, p_H2);

    // Originally (MSL implementation), for all components but: S_h2, S_an, S_cat, S_ch4_gas, S_co2_gas, S_h2_gas
    // Can be used for S_an, S_cat, because ConversionPerComponent = 0 (Stochiometry is = 0)
    // Can be used for S_ch4_gas, S_co2_gas, S_h2_gas, because if InFlux = 0 (although it should be allowed InFlux <> 0)
    for i in TComponentsInLiquid loop
      der(_M[i]) = FluxPerComponent[i] + ConversionTermPerComponent[i]; 
    end for;
    
    for i in TComponentsInGas loop
      der(_M[i]) = FluxPerComponent[i] + ConversionTermPerComponent[i]; 
    end for;

    der(_M[ADM1.TComponents.S_h2]) = 0.0;
     
    p_CH4 = (C[ADM1.TComponents.S_ch4_gas] * (R_Gas / 100) * _TK / 64.0);
    p_CO2 = (C[ADM1.TComponents.S_co2_gas] * (R_Gas / 100) * _TK);
    p_H2 = (C[ADM1.TComponents.S_h2_gas] * (R_Gas / 100) * _TK / 16.0);
    p_H2O = 0.0313 * exp(5290 * ((1/308.15) - (1 / _TK)));
    P_Headspace = p_CO2 + p_H2 + p_CH4 + p_H2O;

    //Q_Gas =  parameters.R * parameters.help_T / (parameters.P_atm - parameters.p_h2o ) * parameters.V_liq * (state.GasKinetics[transfer_ch4] / 64 + state.GasKinetics[transfer_co2] + state.GasKinetics[transfer_h2] / 16); 
    Q_Gas = if (abs((P_Headspace - P_atm) * K_p) <= 1e-008) then 0.0 else ((P_Headspace - P_atm) * K_p);
    QN_Gas  = Q_Gas  * P_Headspace * (1.0 / P_atm);
  
end ConversionModelBaseADM1;

#endif