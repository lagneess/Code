/* Vaneeckhaute C. (2014): NRM-AD model 
   Dynamic anaerobic digestion model including three-phase physicochemical and biological reactions. 
   Should be used with PhreeqC reduced database: AD-PCB. 
   Addition partial pressures (%CH4,...) in biogas
*/

// nog toevoegen in definitions de biological SO4min2 en Kplus
//package NRM_AD

#include "Generic/Generic.mo"
#include "ExternalPhreeq.mo"
#include "Definitions.mo"
//#include "Quantities.mo"

block PtG

  public
    
  parameter Integer FileID = 1; // Needed for PhreeqC function 


// A. INPUTS, OUTPUTS AND OPERATION 

 // Initial conditions 
    input Real Q_liq_in (unit = "m3/d") = 15 "Influent flow rate" annotation (terminal = "in1", group = "Influent"); 
    input Real [TIn] Ins (each unit = "mol/m3") = {6.66, 28.9, 2.89, 0.04, 1.46, 9.95, 72.88, 3.57E-02, 1.23, 3.57E-02, 3.44267E-05, 3.57E-02, 5.10, 3.57E-02, 11.93, 2.56E-07, 1.00E-06, 5.54E-01, 1.68, 0.84, 6.65, 1.28} "Initial concentration vector for species calculation in PhreeqC" annotation (terminal = "in1", group = "Influent");
    input Real [TComponents_X_Bio] BioIns_X (each unit = "kg/m3") = {0, 0, 0, 0.1871, 0, 0, 0, 0.09355, 0.140325, 0, 0, 0, 0, 0, 0, 0} "Initial concentration of biological particulate components" annotation (terminal = "in1", group = "Influent"); 
    input Real [TComponents_sol_Bio] BioIns_S (each unit = "kg/m3") = {0, 0.217025, 0.17025, 1.052475} "Initial concentration of biological soluble components" annotation (terminal = "in1", group = "Influent");  // kg COD/m3
    input Real [TIn_Prec] Ins_Prec (each unit = "kmol/m3") =  {0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000} "Initial precipitate concentration" annotation (terminal = "in1", group = "Influent");       
    input Real [TOut] Outs (each unit = "-") "Initial output PhreeqC" annotation (terminal = "in1", group = "Influent"); // log(kmol/m3) 
    // input Real[TOut_SI] Outs_SI "Initial output PhreeqC as log(SI)" annotation (group = "Influent"); 
    // input Real[TOut_Sol] Outs_Sol "Initial output PhreeqC as log(activity_kmol/m3)" annotation (group = "Influent");
    // input Real[TOut_Gas] Outs_Gas "Initial output PhreeqC as log(SI)" annotation (group = "Influent"); 
  
 // Operational conditions  
    parameter Real T_op (unit = "K") = 302.15 "Operational temperature" annotation (group = "Operation"); 
    parameter Real a_seed (unit = "m2/g") = 600 "Specific area of surface per gram of seed material" annotation (group = "Operation");  
    parameter Real [TSpecies_prec] M_seed (each unit = "kg") = {0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005, 0.0005} "Mass of seed material in the reactor" annotation (group = "Operation"); 
    parameter Real f_X_Out (unit = "-") = 0.002 "Fraction of the anaerobic particulate matter that leaves the reactor" annotation (group = "Operation");
 
 // Dimensions   
    parameter Real Vol_liq (unit = "m3") = 2.8 "Volume of the liquor" annotation (group = "Dimension");
    parameter Real Vol_gas (unit = "m3") = 1 "Headspace volume" annotation (group = "Dimension");
    Real V_liq (unit = "m3", start = 2.8) "Volume of the liquor" annotation (favorite = true, group = "Dimension");
    Real V_gas (unit = "m3") "Headspace volume" annotation (favorite = true, group = "Dimension");
    Real V_tot (unit = "m3") "Reactor volume" annotation (favorite = true, group = "Dimension");

 // Measurements
    Real p_headspace (unit = "atm") "Headspace pressure" annotation (group = "Measurements");
    Real p_h2o (unit = "atm") "Pressure water vapour" annotation (group = "Measurements");
    Real T_ac (unit = "K") "Actual temperature" annotation (group = "Measurements"); 
    Real pH (unit = "-") "Reactor pH" annotation (group = "Measurements");
    Real Q_gas (unit = "m3/d") "Gas flow rate" annotation (terminal = "out3", group = "Gas flow");
    Real QN_gas (unit = "m3/d") "Normalised gas flow rate" annotation (terminal = "out3", group = "Gas flow");
 
 // Output: Measurements 
    output Real pH_AD_PCB (unit = "-")"pH AD_PCB" annotation (terminal = "out4", group = "Measurements");
    output Real T_oper (unit = "K") "Temperature" annotation (terminal = "out4", group = "Measurements");
 
 // Output: Gas flow
    output Real [TComponents_gas] p_Out (each unit = "atm") "Partial pressure" annotation (terminal = "out3", group = "Gas flow");
    output Real [TComponents_gas] p_out_pc (each unit = "%") "Fraction in gas flow" annotation (terminal = "out3", group = "Gas flow");
    output Real p_h2o_Out (unit = "atm") "Pressure water vapour" annotation (terminal = "out3", group = "Gas flow");
    output Real P_Biogas (unit = "atm") "Total headspace pressure" annotation (terminal = "out3", group = "Gas flow");
    output Real Q_Biogas (unit = "m3/d") "Biogas flow rate" annotation (terminal = "out3", group = "Gas flow");

 // Output: Effluent and scaling potential 
    output Real Q_liq_out (unit = "m3/d") "Effluent flow rate" annotation (terminal = "out2", group = "Effluent");
    output Real Alkalinity_out (unit = "eq/L") "Alkalinity in effluent" annotation (terminal = "out2", group = "Effluent");
    output Real [TComponents_sol_PC] C_S_PC_Out (each unit = "M") "Concentration of soluble component in effluent" annotation (terminal = "out2", group = "Effluent") ; 
    output Real [TComponents_P] C_P_Out (each unit = "M") "Concentration of precipitated component in effluent" annotation (terminal = "out2", group = "Effluent") ; 
    output Real C_P_Struvite_out (unit = "M") "Concentration of precipitation struvite in effluent" annotation (terminal = "out2", group = "Effluent"); 
    
    output Real Total_X_COD_out (unit = "kg/d") "Total particulate COD out" annotation (terminal = "out2", group = "Effluent");
    output Real Total_S_COD_out (unit = "kg/d") "Total soluble COD out" annotation (terminal = "out2", group = "Effluent");
  //output Real Control (unit = "M"); 
 
 
// B. QUANTITIES 

 // Define vectors and matrices 
    Real[TReactions] Kinetics_physchem (each unit = "M/d") annotation (group = "Physicochemical reactions");
    Real[TOut_SI] Kinetics_physchem_prec (each unit = "M/d") annotation (group = "Physicochemical precipitation reactions");
    Real[TReactions_gas] Kinetics_physchem_gas (each unit = "M/d") annotation (group = "Physicochemical gas transfer reactions");
    Real[TComponents_Bio] BioIns (each unit = "kg/m3") annotation (terminal = "in1", group = "Influent"); 
    type BiokineticVector = Real[TReactions_bio_liq] (each unit = "kg/m3/d") "Kinetic term biological reactions";
    type BioconversionTermVector = Real[TComponents_Bio] (each unit = "kg/d") "Conversion term biological reactions"; // or kmole/d for the inorganic compounds 
    type StoichiometryMatrix = Real[TReactions_bio_liq, TComponents_Bio] "Gujer Matrix for biological reactions"; 
    Real [TOut_SI] S (each unit = "-") "Saturation ratio" annotation (group = "Influent");
    Real[TOut_Sol] C_Sp (each unit = "kmol/m3") "Species activity" annotation (group = "Influent"); 

 // Define mass (kmol) and activity (kmol/m3) of soluble physicochemical components in the reactor
 // Real [TComponents_sol_PC] M_S_PC (each unit = "kmol", start = {0.097083091, 0.1, 0.90039266, 19.88092527, 168.2226613, 0.1, 13.78485648, 0.1, 0.001542317, 0.1, 7.541201575, 0.1, 12.79579719, 7.18E-07, 2.80E-06, 0.685875164, 0.126373976, 2.320161012, 3.247435351, 1.124699056}) "Mass of soluble physicochemical component in the reactor" annotation (group = "Mass");
    Real [TComponents_sol_PC] M_S_PC (each unit = "kmol") "Mass of soluble physicochemical component in the reactor" annotation (group = "Mass");
    Real [TComponents_sol_PC] C_S_PC (each unit = "M") "Activity of soluble physicochemical component in the liquid phase" annotation (group = "Activity"); 
    Real [TComponents_gas] C_Sol_gas (each unit = "M") "Activity of gas component in the liquid phase" annotation (group = "Activity");

 // Define mass (kg COD) and activity (kg COD/m3) of soluble biological components in the reactor
    Real [TComponents_sol_Bio] M_S_Bio (each unit = "kg", start = {0.0480251548118879, 0.0315077822578224, 1.34314056151464, 0.00159182200853675}) "Mass of soluble biological component in the reactor (kg COD)" annotation (group = "Mass");
    Real [TComponents_sol_Bio] C_S_Bio (each unit = "kg/m3") "Activity of soluble biological component in the liquid phase (kg COD/m3)" annotation (group = "Activity");
    
 // Define mass (kg COD) and activity (kg COD/m3) of particulate biological components in the reactor
    Real [TComponents_X_Bio] M_X (each unit = "kg", start = {0.31441835671414, 0.0498375447377364, 87.6666199916585, 11.2897188063173, 3.71039377430105, 6.45230232705943, 0.35599638625741, 38.6961850128069, 19.5409312859795, 2.7942943370273, 0.0498375447377364, 20.1647413912768, 1.31369884282787, 13.9706680568365, 122.172995699142, 46.3637964792833}) "Mass of particulate component in the reactor" annotation (group = "Mass");
    Real [TComponents_X_Bio] C_X (each unit = "kg/m3") "Activity of particulate component in the liquid phase" annotation (group = "Activity");
 
 // Define mass (kmol) and activity (kmol/m3) of precipitated components in the reactor
    Real [TComponents_P] M_P (each unit = "kmol") "Mass of precipitated component in the reactor" annotation (group = "Mass");  // seed material kan be added 
    Real [TComponents_P] C_P (each unit = "M") "Concentration of precipitated component in the reactor" annotation (group = "Activity");
 
 // Define mass (kmol) and activity (kmol/m3) of precipitated species in the reactor (to be selected)
    Real M_P_Struvite (unit = "kmol") "Mass of precipitated struvite in the reactor" annotation (group = "Mass");
    Real C_P_Struvite (unit = "M") "Concentration  of precipitated struvite in the reactor" annotation (group = "Activity");
 
 // Define mass (kmol), activity (kmol/m3) and partial pressure (atm) of gas phase components 
    Real [TComponents_gas] M_gas (each unit = "kmol") "Mass of gas components in the gas phase" annotation (group = "Mass");
    Real [TComponents_gas] C_gas (each unit = "kmol/m3") "Activity of gas components in the gas phase" annotation (group = "Activity");
    Real [TComponents_gas] p (each unit = "atm") "Partial pressure of components in the gas phase" annotation (group = "Gas pressure");
    Real [TComponents_gas] p_pc (each unit = "%") "Fraction of gas flow" annotation (group = "Gas pressure");
  
 // Define precipitation rate for each component (kmol/m3/d) 
    Real [TComponents_sol_PC] TOut_prec_S (each unit = "M/d") "Precipitation rate" annotation  (group = "Kinetics");
    Real [TComponents_P] TOut_prec_P (each unit = "M/d") "Precipitation rate" annotation  (group = "Kinetics");
    
 // Define liquid-gas transfer rate for each component (kmol/m3/d)      
    Real [TComponents_sol_PC] TOut_gas_S (each unit = "M/d") "Gas transfer rate" annotation (group = "Kinetics");
    Real [TComponents_gas] TOut_gas_G (each unit = "M/d") "Gas transfer rate" annotation (group = "Kinetics");
 
 // Define bioconversion rate for each physicochemical component (kmol/m3/d) 
    Real [TComponents_sol_PC] Bioconversion_PC (each unit = "M/d") "Bioconversion rate" annotation (group = "Kinetics");
 
 // Define physicochemical transport and transformation terms for mass balances (kmol/d) 
    Real [TComponents_sol_PC] Transport_sol_PC (each unit = "kmol/d") "Transport of soluble physicochemical component in the liquid phase" annotation (group = "Transport"); 
    Real [TComponents_sol_PC] Transformation_sol_PC (each unit = "kmol/d") "Transformation of soluble physicochemical component in the liquid phase" annotation (group = "Transformation");      
    Real [TComponents_P] Transport_prec (each unit = "kmol/d") "Transport of precipitated component in the liquid phase" annotation (group = "Transport"); 
    Real [TComponents_P] Transformation_prec (each unit = "kmol/d") "Transformation of precipitated component in the liquid phase" annotation (group = "Transformation");  
    Real [TComponents_gas] Transport_gas (each unit = "kmol/d") "Transport of gas phase components" annotation (group = "Transport"); 
    Real [TComponents_gas] Transformation_gas (each unit = "kmol/d") "Transformation of gas phase components" annotation (group = "Transformation");  
    
 // Define biological transport and transformation terms for mass balances (kg COD/d)       
    Real [TComponents_sol_Bio] Transport_sol_Bio (each unit = "kg/d") "Transport of soluble biological component in the liquid phase" annotation (group = "Transport"); 
    Real [TComponents_sol_Bio] Transformation_sol_Bio (each unit = "kg/d") "Transformation of soluble biological component in the liquid phase" annotation (group = "Transformation");      
    Real [TComponents_X_Bio] Transport_X_Bio (each unit = "kg/d") "Transport of particulate component in the liquid phase" annotation (group = "Transport"); 
    Real [TComponents_X_Bio] Transformation_X_Bio (each unit = "kg/d") "Transformation of particulate component in the liquid phase" annotation (group = "Transformation");  


// C. PARAMETERS 
 
       // *1. PRECIPITATION
 
 // Kinetic precipitation rate coefficients (mol/m2/d) (Arvidson & Mackenzie, 1999; Bénézeth et al., 2008; Chauhan et al., 2011; Grossl and Inskeep, 1991; Ikumi, 2011; Johnson, 1990; Musvoto, 2000; Romanek et al., 2011; Smits & Bleek, 2013)
     parameter Real [TSpecies_prec] k (each unit = "mol/m2/d") = {0.0001, 0.0001, 0.0001, 0.6116651577, 0.00028, 1080, 0.1, 14.64350049, 0.1, 0.1, 11.22, 0.0001, 0.0001192652, 0.1, 986.6476079, 0.00000464, 
     0.0001, 0.000988416, 4.78021E-07, 0.1, 0.00209952, 0.002037407,  1.66165e-06} "Precipitation rate coefficients"  annotation (group = "Kinetics"); 
     parameter Real [TSpecies_prec] k_T (each unit = "mol/m2/d") "T-dependent Precipitation rate" annotation (group = "Kinetics");

  // Enthalpy of heat for precipitation (kJ/mol) (Arvidson & Mackenzie, 1999; Chauhan et al., 2011; Visual Minteq, 2014)
     parameter Real [TSpecies_prec] delta_H (each unit = "kJ/mol") = {-458.6, -258.5901, -7.2, -8.000, -117.6959, -8.000, 31, 23, -105, -103.0519, -31.900, -11, -105, -313.9199, 0, -83.210, 0, 20, 0, 0, -7.300, -0, -5.060} "Reaction enthalpy precipitation" annotation (group = "Stoichiometry"); 
 
  // Reaction order precipitation (-) 
     parameter Real [TSpecies_prec] n (each unit = "-") = {2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2} "Reaction order for precipitation" annotation (group = "Kinetics");

    // *2. GAS TRANSFER
 
  // Kinetic gas transfer rate coefficients (temperature dependent) (1/d)
     parameter Real kLa_O2 (unit = "1/d") = 200 "Gas-Liquid transfer coefficient O2 at 298.15 K" annotation (group = "Kinetics"); 
     Real [TComponents_gas] kLa (each unit = "1/d") "Gas-Liquid transfer coefficient" annotation (group = "Kinetics");

  // Henry coefficients at 298.15 K  and reaction enthalpy (H/R) (kmol/m3/atm) (Sander, 1999) 
     parameter Real [TComponents_gas] kH (each unit = "M/atm") = {0.0014, 0.035, 0.00078, 0.1, 61, 0.00065} "Henry coefficient" annotation (group = "Stoichiometry");	   
     parameter Real [TComponents_gas] H_gas (each unit = "-") = {- 1700, -236534, -500, -3000, -4200, -1300} "Reaction enthalpy gas-liquid transfer" annotation (group = "Stoichiometry");	   

  // Define temperature dependent Henry coefficients (kmol/m3/atm) 
     parameter Real [TComponents_gas] kH_T (each unit = "M/atm") "T-dependent Henry coefficient" annotation (group = "Stoichiometry");
 
  // Liquid-Gas diffusion coefficients (m2/d) measured at temperature T_diff (K) and vector theta indicating T-depency using the Arrhenius equation (Chapra, 2008; Gujer, 2008; Tchobanoglous et al., 2003)
     parameter Real [TComponents_gas] D (each unit = "m2/d")  = {3.771e-5, 1.56e-4, 1.65e-4, 2.2043e-5, 1.69e-4, 1.536e-4} "Liquid-Gas diffusion coefficient" annotation (group = "Kinetics");
     parameter Real [TComponents_gas] T_diff (each unit = "K")  = {298, 293, 298, 298, 298, 293} "Temperature of diffusion coefficient" annotation (group = "Kinetics");	
     parameter Real [TComponents_gas] theta (each unit = "-")  = {1.024, 1.024, 1.024, 1.024, 0, 1.024} "Arrhenius coefficient T-dependency" annotation (group = "Kinetics");	
     parameter Real D_O2 (unit = "m2/d") = 1.608e-4 "Liquid-Gas diffusion coefficient for O2 (= reference)" annotation (group = "Kinetics");

  // Other operational parameters gas phase (Batstone et al., 2002)
     parameter Real K_p (unit = "-") = 5e4 "Gas flow constant" annotation (group = "Operation"); 
     parameter Real p_atm (unit = "atm") = 1 "Atmospheric pressure" annotation (group = "Operation"); 
      
    // *3. BIOLOGICAL TRANSFORMATIONS (Batstone et al., 2002; Knobel & Lewis, 2002; Lizzeralde et al., 2010)
 
  // Carbon content 
     parameter Real C_aa (unit = "mol/g") = 0.03 "Carbon content of amino acids" annotation (group = "Stoichiometry");
     parameter Real C_pr (unit = "mol/g") = 0.03 "Carbon content of proteines" annotation (group = "Stoichiometry");
     parameter Real C_ac (unit = "mol/g") = 0.0313 "Carbon content of acetate" annotation (group = "Stoichiometry");
     parameter Real C_biom (unit = "mol/g") = 0.0313 "Carbon content of biomass" annotation (group = "Stoichiometry");
     parameter Real C_bu (unit = "mol/g") = 0.025 "Carbon content of butyrate" annotation (group = "Stoichiometry");
     parameter Real C_ch4 (unit = "mol/g") = 0.0156 "Carbon content of methane" annotation (group = "Stoichiometry");
     parameter Real C_fa (unit = "mol/g") = 0.0217 "Carbon content of long chain fatty acids" annotation (group = "Stoichiometry");
     parameter Real C_li (unit = "mol/g") = 0.022 "Carbon content of lipids" annotation (group = "Stoichiometry");
     parameter Real C_pro (unit = "mol/g") = 0.0268 "Carbon content of propionate" annotation (group = "Stoichiometry");
     parameter Real C_SI (unit = "mol/g") = 0.03 "Carbon content of soluble inert COD" annotation (group = "Stoichiometry");
     parameter Real C_su (unit = "mol/g") = 0.0313 "Carbon content of sugars" annotation (group = "Stoichiometry");
     parameter Real C_ch (unit = "mol/g") = 0.0313 "Carbon content of carbohydrates" annotation (group = "Stoichiometry");
     parameter Real C_va (unit = "mol/g") = 0.024 "Carbon content of valerate" annotation (group = "Stoichiometry");
     parameter Real C_Xc (unit = "mol/g") = 0.02786 "Carbon content of complex particulate COD" annotation (group = "Stoichiometry");
     parameter Real C_XI (unit = "mol/g") = 0.03 "Carbon content of particulate inert COD" annotation (group = "Stoichiometry");
  
     parameter Real [TSpecies_PC_Bio] COD (each unit = "g/mol") = {64, 160, 64, 1, 1, 16, 1, 1, 1, 1, 112, 1, 208} "COD-content of PCB species" annotation (group = "Stoichiometry");	
  
  // Nitrogen content
     parameter Real N_aa (unit = "mol/g") = 0.007 "Nitrogen content of amino acids" annotation (group = "Stoichiometry");
     parameter Real P_li (unit = "mol/g") = 0.0001129 "Phosphorus content of fatty acids" annotation (group = "Stoichiometry");     
     parameter Real N_biom (unit = "mol/g") = 0.00571428571428571 "Nitrogen content of biomass" annotation (group = "Stoichiometry");
     parameter Real P_biom (unit = "mol/g") = 0.0006457078299 "Phosphorus content of biomass" annotation (group = "Stoichiometry");
     parameter Real K_biom (unit = "mol/g") = 0.0002557655959 "Potassium content of biomass" annotation (group = "Stoichiometry");
     parameter Real S_biom (unit = "mol/g") = 0.0002557655959 "Sulfur content of biomass" annotation (group = "Stoichiometry");
     parameter Real N_SI (unit = "mol/g") = 0.00428571428571429 "Nitrogen content of soluble inert COD" annotation (group = "Stoichiometry");
     parameter Real P_SI (unit = "mol/g") = 0.00020968 "Phosphorus content of soluble inert COD" annotation (group = "Stoichiometry");
     
     parameter Real N_Xc (unit = "mol/g") = 0.00268571428571429 "Nitrogen content of particulate degradable COD" annotation (group = "Stoichiometry");
     parameter Real P_Xc (unit = "mol/g") = 0.000322853915 "Phosphorus content of particulate degradable COD" annotation (group = "Stoichiometry");
     parameter Real K_Xc (unit = "mol/g") = 0.000127882798 "Potassium content of particulate degradable COD" annotation (group = "Stoichiometry");
     parameter Real S_Xc (unit = "mol/g") = 0.000127882798 "Sulfur content of particulate degradable COD" annotation (group = "Stoichiometry");

     parameter Real N_XI (unit = "mol/g") = 0.00428571428571429 "Nitrogen content of particulate inert COD" annotation (group = "Stoichiometry");
     parameter Real P_XI (unit = "mol/g") = 0.00193548 "Phosphorus content of particulate inert COD" annotation (group = "Stoichiometry"); 
     
 
  // Pre-set fractions and yields
     parameter Real f_ac_su (unit = "-") = 0.41 "Yield of acetate from sugar degradation" annotation (group = "Stoichiometry");
     parameter Real f_ac_aa (unit = "-") = 0.4 "Yield of acetate from amino acid degradation" annotation (group = "Stoichiometry");
     parameter Real f_bu_aa (unit = "-") = 0.26 "Yield of butyrate from amino acid degradation" annotation (group = "Stoichiometry");
     parameter Real f_ch_xc (unit = "-") = 0.1 "Yield of carbohydrates from disintegration of complex particulates" annotation (group = "Stoichiometry");
     parameter Real f_fa_li (unit = "-") = 0.95 "Yield of long chain fatty acids (as opposed to glycerol) from lipids" annotation (group = "Stoichiometry");
     parameter Real f_h2_aa (unit = "-") = 0.06 "Yield of hydrogen from amino acid degradation" annotation (group = "Stoichiometry");
     parameter Real f_pro_aa (unit = "-") = 0.05 "Yield of propionate from amino acid degradation" annotation (group = "Stoichiometry");
     parameter Real f_pro_su (unit = "-") = 0.27 "Yield of propionate from monosaccharide degradation" annotation (group = "Stoichiometry");
     parameter Real f_pr_xc (unit = "-") = 0.52 "Yield of proteins from disintegration of complex particulates" annotation (group = "Stoichiometry");
     parameter Real f_SI_xc (unit = "-") = 0.1 "Yield of soluble inerts from disintegration of complex particulates" annotation (group = "Stoichiometry");
     parameter Real f_va_aa (unit = "-") = 0.23 "Yield of valerate from amino acid degradation" annotation (group = "Stoichiometry");
     parameter Real f_XI_xc (unit = "-") = 0.2 "Yield of particulate inerts from disintegration of complex particulates" annotation (group = "Stoichiometry");
     parameter Real f_bu_su (unit = "-") = 0.13 "Yield of butyrate from monosaccharide degradation" annotation (group = "Stoichiometry");
     parameter Real f_h2_su (unit = "-") = 0.19 "Yield of hydrogen from monosaccharide degradation" annotation (group = "Stoichiometry");
     parameter Real f_li_xc (unit = "-") = 0.3 "Yield of lipids from disintegration of complex particulates" annotation (group = "Stoichiometry");
     parameter Real f_co2_h (unit = "mol/gCOD") = 0.00542 "Yield of co2 from hydrogen reduction" annotation (group = "Stoichiometry"); 
     parameter Real f_co2_bu (unit = "mol/gCOD") = 0 "Yield of co2 from butyrate reduction" annotation (group = "Stoichiometry"); 
     parameter Real f_co2_pro (unit = "mol/gCOD") = 0.00850 "Yield of co2 from propionate reduction" annotation (group = "Stoichiometry"); 
     parameter Real f_co2_ac (unit = "mol/gCOD") = 0.02955 "Yield of co2 from acetate reduction" annotation (group = "Stoichiometry"); 
     parameter Real f_s_bu (unit = "mol/gCOD") = 0.00542 "Yield of h2s from S reduction using butyrate" annotation (group = "Stoichiometry"); 
     parameter Real f_s_pro (unit = "mol/gCOD") = 0 "Yield of h2s from S reduction using propionate" annotation (group = "Stoichiometry"); 
     parameter Real f_s_ac (unit = "mol/gCOD") = 0 "Yield of h2s from S reduction using acetate" annotation (group = "Stoichiometry"); 
     parameter Real f_s_h (unit = "mol/gCOD") = 0 "Yield of h2s from S reduction using hydrogen" annotation (group = "Stoichiometry"); 
     
  // Biomass yields 
     parameter Real Y_aa (unit = "-") = 0.08 "Yield of biomass on uptake of amino acids" annotation (group = "Stoichiometry");
     parameter Real Y_ac (unit = "-") = 0.05 "Yield of biomass on uptake of acetate" annotation (group = "Stoichiometry");
     parameter Real Y_c4 (unit = "-") = 0.06 "Yield of biomass on uptake of valerate or butyrate" annotation (group = "Stoichiometry");
     parameter Real Y_fa (unit = "-") = 0.06 "Yield of biomass on uptake of long chain fatty acids" annotation (group = "Stoichiometry");
     parameter Real Y_h2 (unit = "-") = 0.06 "Yield of biomass on uptake of elemental hydrogen" annotation (group = "Stoichiometry");
     parameter Real Y_pro (unit = "-") = 0.04 "Yield of biomass on uptake of propionate" annotation (group = "Stoichiometry");
     parameter Real Y_su (unit = "-") = 0.1 "Yield of biomass on uptake of monosaccharides" annotation (group = "Stoichiometry");
     parameter Real Y_srb_ac (unit = "-") = 0.05437 "Yield of biomass on sulfate reduction using acetate" annotation (group = "Stoichiometry");
     parameter Real Y_srb_bu (unit = "-") = 0.03809 "Yield of biomass on sulfate reduction using butyrate" annotation (group = "Stoichiometry"); 
     parameter Real Y_srb_h (unit = "-") = 0.17355 "Yield of biomass on sulfate reduction using hydrogen" annotation (group = "Stoichiometry");  
     parameter Real Y_srb_pro (unit = "-") = 0.04081 "Yield of biomass on sulfate reduction using propionate" annotation (group = "Stoichiometry"); 
    
  // pH inhibitory/not levels
     parameter Real pH_ac_ll (unit = "-") = 6.3 "pH level at which there is full inhibition of acetate degradation" annotation (group = "Kinetics");
     parameter Real pH_ac_ul (unit = "-") = 9.0 "pH level at which there is no inhibition of acetate degrading organisms" annotation (group = "Kinetics");
     parameter Real pH_bac_ll (unit = "-") = 4.0 "pH level at which there is full inhibition" annotation (group = "Kinetics");
     parameter Real pH_bac_ul (unit = "-") = 5.5 "pH level at which there is no inhibition" annotation (group = "Kinetics");
     parameter Real pH_h2_ll (unit = "-") = 5.3 "pH level at which there is full inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real pH_h2_ul (unit = "-") = 9.0 "pH level at which there is no inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real pH_srb_ul (unit = "-") = 8 "pH level at which there is no inhibition of sulfate reducing bacteria" annotation (group = "Kinetics");  
     parameter Real pH_srb_ll (unit = "-") = 5.5 "pH level at which there is full inhibition of sulfate reducing bacteria" annotation (group = "Kinetics");
     parameter Real alfa_ll (unit = "-") = 6 annotation (group = "Kinetics"); 
     parameter Real alfa_ul (unit = "-") = 6 annotation (group = "Kinetics"); 

  // Inhibitory concentration 
     parameter Real KI_h2_fa (unit = "kg/m3") = 5E-006 "Hydrogen inhibitory concentration for FA degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2_c4 (unit = "kg/m3") = 1E-005 "Hydrogen inhibitory concentration for C4 degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2_pro (unit = "kg/m3") = 3.5E-006 "Inhibitory hydrogen concentration for propionate degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_nh3_ac (unit = "kmol/m3") = 0.0252 "Inhibitory free ammonia concentration for acetate degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2s_bu (unit = "kg/m3") = 0.0156 "Hydrogen sulfide inhibitory concentration for butyrate degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2s_h2 (unit = "kg/m3") = 0.00465 "Hydrogen sulfide inhibitory concentration for hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2s_pro (unit = "kg/m3") = 0.00889 "Inhibitory hydrogen sulfide concentration for propionate degrading organisms" annotation (group = "Kinetics");
     parameter Real KI_h2s_ac (unit = "kg/m3") = 0.00475 "Inhibitory hydrogen sulfide concentration for acetate degrading organisms" annotation (group = "Kinetics");
 
  // Decay and disintegration rates (Henze et al., 2000) 
     parameter Real kdec_xaa (unit = "1/d")= 0.02 "Decay rate for amino acid degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xac (unit = "1/d")= 0.02 "Decay rate for acetate degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xc4 (unit = "1/d")= 0.02 "Decay rate for butyrate and valerate degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xfa (unit = "1/d")= 0.02 "Decay rate for long chain fatty acid degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xh2 (unit = "1/d")= 0.02 "Decay rate for hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xpro (unit = "1/d")= 0.02 "Decay rate for propionate degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xsu (unit = "1/d")= 0.02 "Decay rate for monosaccharide degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xsrbac (unit = "1/d")= 0.02 "Decay rate for long chain fatty acid degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xsrbbu (unit = "1/d")= 0.02 "Decay rate for hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xsrbpro (unit = "1/d")= 0.02 "Decay rate for propionate degrading organisms" annotation (group = "Kinetics");
     parameter Real kdec_xsrbh (unit = "1/d")= 0.02 "Decay rate for monosaccharide degrading organisms" annotation (group = "Kinetics");
 
  // Hydrolysis rates (Henze et al., 2000)
     parameter Real khyd_ch (unit = "1/d") = 10.0 "Carbohydrate hydrolysis first order rate constant" annotation (group = "Kinetics"); 
     parameter Real khyd_li (unit = "1/d") = 10.0 "Lipid hydrolysis first order rate constant" annotation (group = "Kinetics");
     parameter Real khyd_pr (unit = "1/d") = 10.0 "Protein hydrolysis first order rate constant" annotation (group = "Kinetics");
     parameter Real kdis (unit = "1/d") = 0.5 "Complex particulate disintegration first order rate constant" annotation (group = "Kinetics");
   
  // Uptake rates
     parameter Real km_aa (unit = "1/d") = 50.0 "Maximum uptake rate amino acid degrading organisms" annotation (group = "Kinetics");
     parameter Real km_ac (unit = "1/d") = 9.0 "Maximum uptake rate for acetate degrading organisms" annotation (group = "Kinetics");
     parameter Real km_c4 (unit = "1/d") = 20.0 "Maximum uptake rate for c4 degrading organisms" annotation (group = "Kinetics");
     parameter Real km_fa (unit = "1/d") = 6.0 "Maximum uptake rate for long chain fatty acid degrading organisms" annotation (group = "Kinetics");
     parameter Real km_h2 (unit = "1/d") = 35.0 "Maximum uptake rate for hydrogen degrading organisms" annotation (group = "Kinetics");
     parameter Real km_pro (unit = "1/d") = 9.0 "Maximum uptake rate for propionate degrading organisms" annotation (group = "Kinetics");
     parameter Real km_su (unit = "1/d") = 30.0 "Maximum uptake rate for monosaccharide degrading organisms" annotation (group = "Kinetics");
     parameter Real km_srb_bu (unit = "1/d") = 14.51 "Maximum uptake rate for sulfate degrading organisms using butyrate" annotation (group = "Kinetics");
     parameter Real km_srb_pro (unit = "1/d") = 20 "Maximum uptake rate for sulfate degrading organisms using propionate" annotation (group = "Kinetics");
     parameter Real km_srb_ac (unit = "1/d") = 12.55 "Maximum uptake rate for sulfate degrading organisms using acetate" annotation (group = "Kinetics");
     parameter Real km_srb_h2 (unit = "1/d") = 20 "Maximum uptake rate for sulfate degrading organisms using hydrogen" annotation (group = "Kinetics");
     
  // Saturation constants    
     parameter Real Ks_aa (unit = "kg/m3") = 0.3 "Half saturation constant for amino acid degradation" annotation (group = "Kinetics");
     parameter Real Ks_ac (unit = "kg/m3") = 0.15 "Half saturation constant for acetate degradation" annotation (group = "Kinetics");
     parameter Real Ks_c4 (unit = "kg/m3") = 0.2 "Half saturation constant for butyrate and valerate degradation" annotation (group = "Kinetics");
     parameter Real Ks_fa (unit = "kg/m3") = 0.4 "Half saturation constant for long chain fatty acids degradation" annotation (group = "Kinetics");
     parameter Real Ks_h2 (unit = "kg/m3") = 7E-006 "Half saturation constant for uptake of hydrogen" annotation (group = "Kinetics");
     parameter Real Ks_pro (unit = "kg/m3") = 0.1 "Half saturation constant for propionate degradation" annotation (group = "Kinetics");
     parameter Real Ks_su (unit = "kg/m3") = 0.5 "Half saturation constant for monosaccharide degradation" annotation (group = "Kinetics");
     parameter Real Ks_IN (unit = "kg/m3") = 0.0001 "Inorganic nitrogen concentration at which growth ceases" annotation (group = "Kinetics") ; 
     parameter Real Ks_srb_bu (unit = "kg/m3") = 0.28672 "Half saturation constant for butyrate degration by srb's " annotation (group = "Kinetics"); 
     parameter Real Ks_srb_pro (unit = "kg/m3") = 0.04944 "Half saturation constant for propionate degration by srb's" annotation (group = "Kinetics");
     parameter Real Ks_srb_ac (unit = "kg/m3") = 0.024 "Half saturation constant for acetate degration by srb's" annotation (group = "Kinetics"); 
     parameter Real Ks_srb_h2 (unit = "kg/m3") = 0.024E-003 "Half saturation constant for hydrogen degration by srb's" annotation (group = "Kinetics");
     parameter Real Ks_so4_bu (unit = "kg/m3") = 0.00017 "Half saturation constant for sulfate degration using butyrate" annotation (group = "Kinetics"); 
     parameter Real Ks_so4_pro (unit = "kg/m3") = 0.000077 "Half saturation constant for sulfate degration using propionate" annotation (group = "Kinetics"); 
     parameter Real Ks_so4_ac (unit = "kg/m3") = 0.0002 "Half saturation constant for sulfate degration using acetate" annotation (group = "Kinetics"); 
     parameter Real Ks_so4_h2 (unit = "kg/m3") = 0.0093E-003 "Half saturation constant for sulfate degration using hydrogen" annotation (group = "Kinetics"); 
     
  // Inhibition factors 
     Real I_h2_fa (unit = "-") "Hydrogen inhibition for LCFA degradation" annotation (group = "Kinetics");
     Real I_h2_c4 (unit = "-") "Hydrogen inhibition for C4+ degradation" annotation (group = "Kinetics");
     Real I_h2_pro (unit = "-") "Hydrogen inhibition for propionate" annotation (group = "Kinetics");
     Real I_nh3_ac (unit = "-") "NH3 inhibition of acetoclastic methanogenesis" annotation (group = "Kinetics");
     Real I_NH_limit (unit = "-") "Function to limit growth due to lack of inorganic nitrogen" annotation (group = "Kinetics");
     Real I_pH_ac (unit = "-") "pH inhibition of acetate degrading organisms" annotation (group = "Kinetics");
     Real I_pH_bac (unit = "-") "pH inhibition of acetogens and acidogens" annotation (group = "Kinetics");  // <-- (lower inhibition only used here)
     Real I_pH_h2 (unit = "-") "pH inhibition of hydrogen degrading organisms" annotation (group = "Kinetics");
     Real I_pH_srb (unit = "-") "pH inhibition of sulfate reducing bacteria" annotation (group = "Kinetics");
     Real I_h2s_ac (unit = "-") "Hydrogen sulfide inhibition" annotation (group = "Kinetics");
     Real I_h2s_bu (unit = "-") "Hydrogen sulfide inhibition" annotation (group = "Kinetics");
     Real I_h2s_pro (unit = "-") "Hydrogen sulfide inhibition" annotation (group = "Kinetics"); 
     Real I_h2s_h2 (unit = "-") "Hydrogen sulfide inhibition" annotation (group = "Kinetics");
       
 protected   
   
     Real Dummy; 
     Real Zero = 0; // needed for ordering of equations
     Real[TOut] TempOuts; // needed for ordering of equations 
   
  // Constants 
     constant Real R_Gas (unit = "atm.m3/kmol/K") = 0.08206 "Universal gas law constant"; 
     constant Real R (unit = "kJ/kmol/K") = 8.314 "Universal gas law constant"; 
  
 // Stoichiometric precipitation coefficients (total number of species)  
     constant Real [TSpecies_prec] v (each unit = "-") = {2, 5, 2, 2, 3, 2, 3, 3, 8, 3, 4, 2, 4, 7, 21, 3, 2, 2, 3, 5, 2, 3, 5} "Stoichiometric precipitation coefficient" annotation (group = "Stoichiometry");       

  // Stoichiometric matrix species calculation using the Tableau method (Morel and Hering, 1993)
     constant Real[TComponents_sol_PC, TOut_Sol] Sp_Comp  = 
     {{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},	
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},		
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0},
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}} "Stoichiometric matrix species calculation" annotation (group = "Stoichiometry");

  // Stoichiometric matrix precipitation using the Tableau method (Morel and Hering, 1993)
     constant Real[TComponents_P, TSpecies_prec] prec_Comp  = 
     {{1, 2, 0, 0, 1, 0, 0, 0, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
     {0, 0, 0, 1, 0, 1, 1, 1, 4, 0, 1, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0},  
     {0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0},    
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 3},  
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0},    
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 3, 0, 1, 0},    
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0},        
     {1, 0, 0, 0, 0, 0, 1, 1, 3, 0, 0, 0, 0, 0, 6, 1, 0, 0, 1, 2, 0, 1, 2},  
     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0},
     {0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0}} "Stoichiometric matrix precipitation" annotation (group = "Stoichiometry"); 
  
  // Define stoichiomatric matrix biological conversions
     parameter StoichiometryMatrix Stoichiometry "Body of the Gujer Matrix" annotation (group = "_Stoichiometry");
     BioconversionTermVector Bioconversion "Vector of conversion rates" annotation (group = "Conversion");
     BiokineticVector Kinetics "Rate column of the Gujer Matrix" annotation (group = "Kinetics");    
     
  // State variables needed in Hill function
     Real pHLim_ac (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");
     Real pHLim_bac (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");
     Real pHLim_h2 (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");
     Real n_ac (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");
     Real n_bac (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");
     Real n_h2 (unit = "-") "state needed in Hill function" annotation (group = "Kinetics");

  // COD balances 
     Real balance_COD_S (unit = "kg/m3") "Total COD of soluble substrate" annotation (group = "Continuity");
     Real balance_COD_X (unit = "kg/m3") "Total COD of particulate substrate" annotation (group = "Continuity");   

 initial equation    
 
  // 1. REACTOR MODEL (CSTR)
        V_liq = Vol_liq;
        V_tot = Vol_gas + Vol_liq;
        T_ac = Outs[TOut.temp] + 273.15;
   
  
  // 2. BIOLOGICAL PROCESSES: STOICHIOMETRY (Batstone et al., 2002; Knobel & Lewis, 2002; Lizzeralde et al., 2010)
     // process 1: decay of amino acid degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.X_aa] = -1;
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.NH4plus] = N_biom - N_Xc; // in kmol / m3     
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_aa, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
      // process 2: decay of acetate degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.X_ac] = -1;
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.NH4plus] = N_biom - N_Xc; 
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_ac, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 3: decay of butyrate and valerate degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.X_c4] = -1;
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.CO3min2] = C_biom - C_Xc;
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.NH4plus] = N_biom - N_Xc;
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.PO4min3] = P_biom- P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_c4, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 4: decay of LCFA degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.X_fa] = -1;
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.CO3min2] = C_biom - C_Xc;
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.NH4plus] = N_biom - N_Xc;
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_fa, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 5: decay of hydrogen degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.X_h2] = -1;
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.CO3min2] = C_biom - C_Xc;
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.NH4plus] = N_biom - N_Xc;
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.PO4min3] = P_biom; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_h2, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 6: decay of propionate degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.X_pro] = -1;
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.CO3min2] = C_biom - C_Xc;
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.NH4plus] = N_biom - N_Xc;
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_pro, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3        
    // process 7: decay of monosaccharide degrading organisms
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.X_su] = -1;
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.CO3min2] = C_biom -C_Xc;
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.NH4plus] = N_biom -N_Xc;
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_su, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 8: first order disintegration of complex particulates
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.X_c] = -1;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.X_ch] = f_ch_xc;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.X_pr] = f_pr_xc;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.X_Inert] = f_XI_xc;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.X_li] = f_li_xc;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.S_Inert] = f_SI_xc;  
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.CO3min2] = C_Xc - f_ch_xc * C_ch - f_SI_xc * C_SI - f_pr_xc * C_pr -  f_XI_xc * C_XI - f_li_xc * C_li;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.NH4plus] = N_Xc -f_XI_xc * N_XI -f_SI_xc * N_SI -f_pr_xc * N_aa;
        Stoichiometry[TReactions_bio_liq.dis, TComponents_Bio.PO4min3] = P_Xc - f_XI_xc * P_XI -f_SI_xc * P_SI - f_li_xc * P_li;
     // process 9: first order hydrolysis of carbohydrates
        Stoichiometry[TReactions_bio_liq.hyd_ch, TComponents_Bio.S_su] = 1;
        Stoichiometry[TReactions_bio_liq.hyd_ch, TComponents_Bio.X_ch] = -1;
        Stoichiometry[TReactions_bio_liq.hyd_ch, TComponents_Bio.CO3min2] = C_ch - C_su; 
     // process 10: first order hydrolysis of lipids
        Stoichiometry[TReactions_bio_liq.hyd_li, TComponents_Bio.S_su] = 1 -f_fa_li;
        Stoichiometry[TReactions_bio_liq.hyd_li, TComponents_Bio.S_fa] = f_fa_li;
        Stoichiometry[TReactions_bio_liq.hyd_li, TComponents_Bio.X_li] = -1;
        Stoichiometry[TReactions_bio_liq.hyd_li, TComponents_Bio.CO3min2] = (f_fa_li - 1) * C_su - f_fa_li * C_fa + C_li;
        Stoichiometry[TReactions_bio_liq.hyd_li, TComponents_Bio.PO4min3] = P_li;
     // process 11: first order hydrolysis of proteins
        Stoichiometry[TReactions_bio_liq.hyd_pr, TComponents_Bio.S_aa] = 1;
        Stoichiometry[TReactions_bio_liq.hyd_pr, TComponents_Bio.X_pr] = -1;
        Stoichiometry[TReactions_bio_liq.hyd_pr, TComponents_Bio.CO3min2] = C_aa - C_pr;
     // process 12: uptake of amino acids 
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.H2] = (1-Y_aa)*f_h2_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.CO3min2] = C_aa - (1-Y_aa) * f_ac_aa * C_ac - (1-Y_aa) * f_bu_aa * C_bu -(1 -Y_aa) * f_pro_aa * C_pro -(1-Y_aa) * f_va_aa * C_va - Y_aa * C_biom;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.Acetatemin] = (1-Y_aa) * f_ac_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.Butyratemin] = (1-Y_aa) * f_bu_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.S_aa] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.Propionatemin] = (1-Y_aa) * f_pro_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.Valeratemin] = (1-Y_aa) * f_va_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.NH4plus] = N_aa - Y_aa * N_biom;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.X_aa] = Y_aa;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.PO4min3] = -Y_aa * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.SO4min2] = -Y_aa * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_aa, TComponents_Bio.Kplus] = -Y_aa * K_biom;
     // process 13: uptake of acetate
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.Acetatemin] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.X_ac] = Y_ac;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.NH4plus] = -N_biom * Y_ac;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.CH4] =1-Y_ac;  
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.CO3min2] = C_ac -Y_ac * C_biom -(1-Y_ac) * C_ch4;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.PO4min3] = -Y_ac * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.SO4min2] = -Y_ac * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_ac, TComponents_Bio.Kplus] = -Y_ac * K_biom;
    // process 14: uptake of butyrate
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.H2] = (1 -Y_c4 )*0.2;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.Acetatemin] = (1 -Y_c4 )*0.8;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.X_c4] = Y_c4;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.NH4plus] = -N_biom * Y_c4;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.Butyratemin] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.CO3min2] = C_bu - (1 -Y_c4 )* 0.8 * C_ac - Y_c4 * C_biom;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.PO4min3] = -Y_c4 * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.SO4min2] = -Y_c4 * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_bu, TComponents_Bio.Kplus] = -Y_c4 * K_biom;
     // process 15: uptake of LCFA
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.H2] = (1-Y_fa)*0.3;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.Acetatemin] = (1-Y_fa)*0.7;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.X_fa] = Y_fa;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.NH4plus] = -N_biom * Y_fa;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.S_fa] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.CO3min2] = C_fa - (1-Y_fa) * 0.7 * C_ac - Y_fa * C_biom;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.PO4min3] =-Y_fa * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.SO4min2] = -Y_fa * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_fa, TComponents_Bio.Kplus] = -Y_fa * K_biom;
     // process 16: uptake of h2 by HM
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.H2] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.X_h2] = Y_h2;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.NH4plus] = -N_biom * Y_h2;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.CH4] = 1 - Y_h2;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.CO3min2] = -Y_h2 * C_biom - (1 -Y_h2) * C_ch4;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.PO4min3] = -Y_h2 * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.SO4min2] = -Y_h2 * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_h2, TComponents_Bio.Kplus] = -Y_h2 * K_biom;
    // process 17: uptake of propionate
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.H2] = (1-Y_pro)*0.43;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.Acetatemin] = (1-Y_pro)*0.57;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.X_pro] = Y_pro;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.NH4plus] = -N_biom * Y_pro;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.Propionatemin] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.CO3min2] = C_pro -(1 -Y_pro) * 0.57 * C_ac -Y_pro * C_biom;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.PO4min3] = -Y_pro * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.SO4min2] = -Y_pro * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_pro, TComponents_Bio.Kplus] = -Y_pro * K_biom;
     // process 18: uptake of monosaccharides
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.H2] = (1-Y_su) * f_h2_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.CO3min2] = C_su -(1 - Y_su) * f_ac_su * C_ac -(1 -Y_su) * f_pro_su * C_pro -(1 -Y_su) * f_bu_su * C_bu -Y_su * C_biom;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.Acetatemin] = (1 -Y_su) * f_ac_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.X_su] = Y_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.NH4plus] = -N_biom * Y_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.S_su] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.Butyratemin] = (1-Y_su) * f_bu_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.Propionatemin] = (1-Y_su) * f_pro_su;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.PO4min3] = -Y_su * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.SO4min2] = -Y_su * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_su, TComponents_Bio.Kplus] = -Y_su * K_biom;
     // process 19: uptake of valerate
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.H2] = (1-Y_c4)*0.15;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.Acetatemin] = (1-Y_c4)*0.31;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.X_c4] = Y_c4;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.NH4plus] = -N_biom * Y_c4;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.Valeratemin] = -1;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.Propionatemin] = (1-Y_c4)*0.54;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.CO3min2] = C_va - (1-Y_c4)*0.54 * C_pro - Y_c4 * C_biom - (1-Y_c4) * 0.31 * C_ac;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.PO4min3] = -Y_c4 * P_biom;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.SO4min2] = -Y_c4 * S_biom;
        Stoichiometry[TReactions_bio_liq.uptake_va, TComponents_Bio.Kplus] = -Y_c4 * K_biom;
     // process 20: Butyrate sulphate reduction
        Stoichiometry[TReactions_bio_liq.reduction_srb_bu, TComponents_Bio.Butyratemin] = -1;
        Stoichiometry[TReactions_bio_liq.reduction_srb_bu, TComponents_Bio.X_srb_bu] = Y_srb_bu;
        Stoichiometry[TReactions_bio_liq.reduction_srb_bu, TComponents_Bio.CO2] = f_co2_bu;
        Stoichiometry[TReactions_bio_liq.reduction_srb_bu, TComponents_Bio.SO4min2] = -f_s_bu;
        Stoichiometry[TReactions_bio_liq.reduction_srb_bu, TComponents_Bio.H2S] = f_s_bu;
     // process 21: Propionate sulphate reduction
        Stoichiometry[TReactions_bio_liq.reduction_srb_pro, TComponents_Bio.Propionatemin] = -1;
        Stoichiometry[TReactions_bio_liq.reduction_srb_pro, TComponents_Bio.X_srb_pro] = Y_srb_pro;
        Stoichiometry[TReactions_bio_liq.reduction_srb_pro, TComponents_Bio.CO2] = f_co2_pro;
        Stoichiometry[TReactions_bio_liq.reduction_srb_pro, TComponents_Bio.SO4min2] = -f_s_pro;
        Stoichiometry[TReactions_bio_liq.reduction_srb_pro, TComponents_Bio.H2S] = f_s_pro;          
     // process 22: Acetate sulphate reduction
        Stoichiometry[TReactions_bio_liq.reduction_srb_ac, TComponents_Bio.Acetatemin] = -1;
        Stoichiometry[TReactions_bio_liq.reduction_srb_ac, TComponents_Bio.X_srb_ac] = Y_srb_ac;
        Stoichiometry[TReactions_bio_liq.reduction_srb_ac, TComponents_Bio.CO2] = f_co2_ac;
        Stoichiometry[TReactions_bio_liq.reduction_srb_ac, TComponents_Bio.SO4min2] = -f_s_ac;
        Stoichiometry[TReactions_bio_liq.reduction_srb_ac, TComponents_Bio.H2S] = f_s_ac;           
     // process 23: Hydrogen sulphate reduction 
        Stoichiometry[TReactions_bio_liq.reduction_srb_h, TComponents_Bio.H2] = -1;
        Stoichiometry[TReactions_bio_liq.reduction_srb_h, TComponents_Bio.X_srb_h] = Y_srb_h;
        Stoichiometry[TReactions_bio_liq.reduction_srb_h, TComponents_Bio.CO2] = f_co2_h;
        Stoichiometry[TReactions_bio_liq.reduction_srb_h, TComponents_Bio.SO4min2] = -f_s_h;
        Stoichiometry[TReactions_bio_liq.reduction_srb_h, TComponents_Bio.H2S] = f_s_h;  
     // process 24: Decay of srb_ac
        Stoichiometry[TReactions_bio_liq.decay_srb_ac, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_srb_ac, TComponents_Bio.X_srb_ac] = -1;
        Stoichiometry[TReactions_bio_liq.decay_srb_ac, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_srb_ac, TComponents_Bio.NH4plus] = N_biom - N_Xc; // in kmol / m3     
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 25: Decay of srb_pro
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.X_srb_pro] = -1;
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.NH4plus] = N_biom - N_Xc; // in kmol / m3     
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_pro, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
     // process 24: Decay of srb_bu
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.X_srb_bu] = -1;
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.NH4plus] = N_biom - N_Xc; // in kmol / m3     
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_bu, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
 // process 24: Decay of srb_ac
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.X_c] = 1;
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.X_srb_h] = -1;
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.CO3min2] = C_biom - C_Xc;  
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.NH4plus] = N_biom - N_Xc; // in kmol / m3     
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.PO4min3] = P_biom - P_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.Kplus] = K_biom - K_Xc; // in kmol / m3   
        Stoichiometry[TReactions_bio_liq.decay_srb_h, TComponents_Bio.SO4min2] = S_biom - S_Xc; // in kmol / m3    
  
  equation
       
       
 // 1. EXTERNAL PHREEQC FUNCTION
       Dummy = TornadoPhreeqc(ref(Ins[TIn.pH]), size(Ins,1), ref(TempOuts[TOut.pH]), size(TempOuts,1), FileID) + Zero * sum(Ins);    
       Outs = TempOuts .+ Dummy;
       
       
 // 2. REACTOR MODEL (CSTR, CONSTANT VOLUME)
       der(V_liq) = 0;
       V_gas = V_tot - V_liq;
       Q_liq_out = Q_liq_in;
         
         
 // 3. MODEL CONNECTIONS 
     
    // a) Link biological components to PhreeqC speciation output + convert from kmol/m3 to kg COD/m3
       BioIns[TComponents_Bio.Acetatemin] = C_Sp[TOut_Sol.Acetatemin]* COD[TSpecies_PC_Bio.Acetatemin];
       BioIns[TComponents_Bio.Butyratemin] = C_Sp[TOut_Sol.Butyratemin] * COD[TSpecies_PC_Bio.Butyratemin]; 
       BioIns[TComponents_Bio.CH4] = C_Sp[TOut_Sol.CH4] * COD[TSpecies_PC_Bio.CH4]; 
       BioIns[TComponents_Bio.CO2] = C_Sp[TOut_Sol.CO2]; 
       BioIns[TComponents_Bio.CO3min2] = C_Sp[TOut_Sol.CO3min2]; 
       BioIns[TComponents_Bio.H2] = C_Sp[TOut_Sol.H2] * COD[TSpecies_PC_Bio.H2]; 
       BioIns[TComponents_Bio.H2S] = C_Sp[TOut_Sol.H2S]; 
       BioIns[TComponents_Bio.Kplus] = C_Sp[TOut_Sol.Kplus];
       BioIns[TComponents_Bio.NH4plus] = C_Sp[TOut_Sol.NH4plus]; 
       BioIns[TComponents_Bio.PO4min3] = C_Sp[TOut_Sol.PO4min3]; 
       BioIns[TComponents_Bio.Propionatemin] = C_Sp[TOut_Sol.Propionatemin] * COD[TSpecies_PC_Bio.Propionatemin]; 
       BioIns[TComponents_Bio.SO4min2] = C_Sp[TOut_Sol.SO4min2]; 
       BioIns[TComponents_Bio.Valeratemin] = C_Sp[TOut_Sol.Valeratemin] * COD[TSpecies_PC_Bio.Valeratemin];
    // b) Link precipitation soluble components to precipitated components
       TOut_prec_S[TComponents_sol.S_Al] = TOut_prec_P[TComponents_P.P_Al];
       TOut_prec_S[TComponents_sol.S_C_4_] = TOut_prec_P[TComponents_P.P_C_4_];
       TOut_prec_S[TComponents_sol.S_Ca] = TOut_prec_P[TComponents_P.P_Ca];
       TOut_prec_S[TComponents_sol.S_Fe] = TOut_prec_P[TComponents_P.P_Fe];
       TOut_prec_S[TComponents_sol.S_K] = TOut_prec_P[TComponents_P.P_K];
       TOut_prec_S[TComponents_sol.S_Mg] = TOut_prec_P[TComponents_P.P_Mg];
       TOut_prec_S[TComponents_sol.S_N_min3_] = TOut_prec_P[TComponents_P.P_N_min3_];
       TOut_prec_S[TComponents_sol.S_P] = TOut_prec_P[TComponents_P.P_P];  
       TOut_prec_S[TComponents_sol.S_S_min2_] = TOut_prec_P[TComponents_P.P_S_min2_];   
    // c) Link liquid-gas transfer of soluble components to gas phase components 
       TOut_gas_S[TComponents_sol.S_C_min4_] = TOut_gas_G[TComponents_gas.CH4_g_]; 
       TOut_gas_S[TComponents_sol.S_C_4_] = TOut_gas_G[TComponents_gas.CO2_g_];
       TOut_gas_S[TComponents_sol.S_H_0_] = TOut_gas_G[TComponents_gas.H2_g_];
       TOut_gas_S[TComponents_sol.S_N_min3_] = TOut_gas_G[TComponents_gas.NH3_g_]; 
       TOut_gas_S[TComponents_sol.S_N_0_] = TOut_gas_G[TComponents_gas.N2_g_];  
       TOut_gas_S[TComponents_sol.S_S_min2_] = TOut_gas_G[TComponents_gas.H2S_g_]; 
    // d) Link molar activities of gas components in the liquid phase to PhreeqC speciation output (kmol/m3)
       C_Sol_gas[TComponents_gas.CH4_g_] = C_Sp[TOut_Sol.CH4];
       C_Sol_gas[TComponents_gas.CO2_g_] = C_Sp[TOut_Sol.CO2];   
       C_Sol_gas[TComponents_gas.H2_g_] = C_Sp[TOut_Sol.H2];
       C_Sol_gas[TComponents_gas.H2S_g_] = C_Sp[TOut_Sol.H2S];
       C_Sol_gas[TComponents_gas.NH3_g_] = C_Sp[TOut_Sol.NH3];
       C_Sol_gas[TComponents_gas.N2_g_] = C_Sp[TOut_Sol.N2];
    // e) Link bioconversion of biological species to soluble physicochemical components + conversion kg COD/m3 to kmol/m3 
       Bioconversion_PC[TComponents_sol_PC.S_N_min3_] = Bioconversion[TComponents_Bio.NH4plus]; 
       Bioconversion_PC[TComponents_sol_PC.S_S_6_] = Bioconversion[TComponents_Bio.SO4min2]; 
       Bioconversion_PC[TComponents_sol_PC.S_S_min2_] = Bioconversion[TComponents_Bio.H2S];   
       Bioconversion_PC[TComponents_sol_PC.S_C_4_] = Bioconversion[TComponents_Bio.CO3min2] + Bioconversion[TComponents_Bio.CO2];  
       Bioconversion_PC[TComponents_sol_PC.S_C_min4_] = Bioconversion[TComponents_Bio.CH4] / COD[TSpecies_PC_Bio.CH4];  
       Bioconversion_PC[TComponents_sol_PC.S_Valerate] = Bioconversion[TComponents_Bio.Valeratemin] / COD[TSpecies_PC_Bio.Valeratemin];  
       Bioconversion_PC[TComponents_sol_PC.S_Butyrate] = Bioconversion[TComponents_Bio.Butyratemin] / COD[TSpecies_PC_Bio.Butyratemin];    
       Bioconversion_PC[TComponents_sol_PC.S_Propionate] = Bioconversion[TComponents_Bio.Propionatemin] / COD[TSpecies_PC_Bio.Propionatemin];  
       Bioconversion_PC[TComponents_sol_PC.S_Acetate] = Bioconversion[TComponents_Bio.Acetatemin] / COD[TSpecies_PC_Bio.Acetatemin];    

 
 // 4. SPECIES CALCULATION
 
    // Total activity of physicochemical species in solution after PhreeqC speciation (kmol/m3) 
       for i in TOut_Sol loop
           C_Sp[i] = if Outs[i] <= -999.999 then 0.0   
           else 10.^Outs[i]; 
       end for;
 	
    // Total activity of physicochemical components in solution after PhreeqC speciation (kmol/m3) 
       C_S_PC = Sp_Comp * C_Sp;// of is dit 'in' 
  
 /*    // Total mass of physicochemical components in the reactor after PhreeqC speciation (kmol)	
       for i in TComponents_sol_PC loop
          M_S_PC[i] = C_S_PC[i] * V_liq;
       end for;
*/

 // 5. PRECIPITATION CALCULATIONS

    // T-dependent precipitation rate constants using the Arrhenius equation (mol/m2/d)
       k_T = k .* exp((delta_H .+ R * T_op)/(R * T_op));  	 
    
    // Saturation index from output PhreeqC: Selection of oversaturated species 
          for i in TOut_SI loop
              S[i] = if Outs[i] < 0 then 0.0 
              else ((10.^Outs[i]).^(v[i].^(-1))); 
          end for;
          
       // Dynamic precipitation reactions based on relative supersaturation and reactor seed material using the Nielsen equation (kmol/m3/d) (Nielsen, 1984) 
          for i in TOut_SI loop 
         	    Kinetics_physchem_prec[i] = if S[i] <= 0 then 0.0
              else (k_T[i] .* a_seed .* (M_seed[i]/V_liq) .* ((S[i]) .- 1).^(n[i])); 
          end for; 
 /*  
   // Saturation index from output PhreeqC: Selection of oversaturated species 
       for i in TOut_SI loop
            SI[i] = if Outs[i] < 0 then 0.0    
            else 10.^Outs[i]; 
       end for; 
 
    // Dynamic precipitation reactions based on relative supersaturation and reactor seed material using the Nielsen equation (kmol/m3/d) (Nielsen, 1984) 
       for i in TOut_SI loop 
      	   Kinetics_physchem_prec[i] = if SI[i] <= 0 then 0.0
           else (k_T[i] .* a_seed .* (M_seed[i]/V_liq) .* (v[i].^(-1)) .* (SI[i] .- 1).^(1/2)); 
       end for;
   */    
    // Conversion term for precipitation reactions (kmol/m3/d)        
       TOut_prec_P = prec_Comp * Kinetics_physchem_prec; 

    // Concentration of precipitated components in the reactor (kmol/m3)	
       for i in TComponents_P loop
	   C_P[i] = M_P[i] / V_liq;
       end for;
    
    // Concentration of precipitated species in the reactor (to be selected) (kmol/m3) 
       C_P_Struvite = (M_P_Struvite / V_liq); 
  
  
 // 6. GAS TRANSFER CALCULATIONS

    // T-dependent Henry constants using the Van't Hoff equation (M/atm) 
       kH_T = kH .* exp(H_gas * ((1/T_op) - (1/298.15)));
 
    // T-dependent liquid-gas mass transfer rate using the Arrhenius equation (/d) (Chapra, 2008; Tchobanoglous et al., 2003) 
    // Note: NH3 transfer cannot be calculated using O2 as reference, kLa = 3.2 = very low, no NH3-stripping (Sotemann et al., 2006)
       for i in TComponents_gas loop
       	   kLa[i] = if (theta[i] <= 0) then 3.2 
       	   else (theta[i] .^(T_op - T_diff[i]) * sqrt(D[i]/D_O2) * kLa_O2); 
       end for;  
   /*    
    // Total mass of each component in the gas phase (kmol) 
       for i in TComponents_gas loop
       	   M_gas[i] = if (Outs[i] <= -999.999) then 0.0 
       	   else ((10.^Outs[i] * V_gas) / (R_Gas * T_op)); 
       end for; 
        
    // Total concentration of each component in the gas phase (kmol/m3)
       for i in TComponents_gas loop
       	   C_gas[i] = M_gas[i] / V_gas;
       end for; 
   */
         
       // Total mass of each component in the gas phase (kmol) 
          for i in TComponents_gas loop
          	   C_gas[i] = if (Outs[i] <= -999.999) then 0.0 
          	   else ((10.^Outs[i]) / (R_Gas * T_op)); 
          end for; 
           
     /*  // Total concentration of each component in the gas phase (kmol/m3)
          for i in TComponents_gas loop
          	   M_gas[i] = C_gas[i] * V_gas;
          end for; 
   */

  
    // Dynamic gas transfer using the two-film theory (kmol/m3/d) (Tchobanoglous et al., 2003) 
       Kinetics_physchem_gas = kLa .* (C_Sol_gas .- kH_T .* C_gas .* R_Gas .* T_op); 
       Kinetics_physchem[TReactions.transfer_H2O] = (0.0313 * exp(5290 * ((1/T_op) - (1/298.15)))) / (R_Gas * T_op);
       
    // Conversion term for gas transfer reactions (kmol/m3/d)
       TOut_gas_G = Kinetics_physchem_gas; 
 
 
 // 7. BIOLOGICAL CONVERSIONS
 
    // Preliminary calculations for the biological inhibitions (Batstone et al., 2002; Knobel & Lewis, 2002; Lizzeralde et al., 2010)
       I_h2_fa = 1 / (BioIns[TComponents_Bio.H2] / KI_h2_fa + 1);
       I_h2_c4 = 1 / (BioIns[TComponents_Bio.H2] / KI_h2_c4 + 1); 
       I_h2_pro = 1 / (BioIns[TComponents_Bio.H2] / KI_h2_pro + 1);
       I_nh3_ac = 1 / (C_Sol_gas[TComponents_gas.NH3_g_] / KI_nh3_ac + 1);
       I_NH_limit = if (abs(BioIns[TComponents_Bio.NH4plus]) <= 1e-008) then 0.0 else (1 / (Ks_IN / BioIns[TComponents_Bio.NH4plus] + 1));
       I_h2s_ac = KI_h2s_ac / (KI_h2s_ac + BioIns[TComponents_Bio.H2S]);
       I_h2s_bu = KI_h2s_bu / (KI_h2s_bu + BioIns[TComponents_Bio.H2S]);
       I_h2s_pro = KI_h2s_pro / (KI_h2s_pro + BioIns[TComponents_Bio.H2S]);
       I_h2s_h2 = KI_h2s_h2 / (KI_h2s_h2 + C_Sp[TOut_Sol.Hplus]); 
   
    // Hill functions on SH+ for calculation of inhibition terms (Batstone et al., 2002; Knobel & Lewis, 2002; Lizzeralde et al., 2010)
       pHLim_ac = pow(10,(-(pH_ac_ul + pH_ac_ll) / 2.0));
       pHLim_bac = pow(10,(-(pH_bac_ul + pH_bac_ll) / 2.0));
       pHLim_h2 = pow(10,(-(pH_h2_ul + pH_h2_ll) / 2.0));
       n_ac = 3.0 / (pH_ac_ul - pH_ac_ll);
       n_bac = 3.0 / (pH_bac_ul - pH_bac_ll);
       n_h2 = 3.0 / (pH_h2_ul - pH_h2_ll);
       I_pH_ac = pow(pHLim_ac, n_ac) / (pow(C_Sp[TOut_Sol.Hplus], n_ac) + pow(pHLim_ac, n_ac));
       I_pH_bac = pow(pHLim_bac, n_bac) / (pow(C_Sp[TOut_Sol.Hplus], n_bac) + pow(pHLim_bac, n_bac));
       I_pH_h2 = pow(pHLim_h2, n_h2) / (pow(C_Sp[TOut_Sol.Hplus], n_h2) + pow(pHLim_h2, n_h2));
       I_pH_srb = (1 / (1 + exp(- alfa_ll * (Outs[TOut.pH] - pH_srb_ll))))* (1 / (1 + exp(- alfa_ul * (Outs[TOut.pH] - pH_srb_ul)))); 
   
    // Concentration of particulate biological components in the reactor (kg COD/m3) 
       for i in TComponents_X_Bio loop
       	    C_X[i] = M_X[i] / V_liq;
       end for;
    
    // Concentration of soluble biological components in the reactor (kg COD/m3) 
       for i in TComponents_sol_Bio loop
	    C_S_Bio[i] = M_S_Bio[i] / V_liq;
       end for;
      
    // Biological kinetic transformations (kg COD/m3/d) (Batstone et al., 2002; Knobel & Lewis, 2002; Lizzeralde et al., 2010)
       Kinetics[TReactions_bio_liq.decay_aa] = kdec_xaa * C_X[TComponents_Bio.X_aa];
       Kinetics[TReactions_bio_liq.decay_ac] = kdec_xac * C_X[TComponents_Bio.X_ac];
       Kinetics[TReactions_bio_liq.decay_c4] = kdec_xc4 * C_X[TComponents_Bio.X_c4];
       Kinetics[TReactions_bio_liq.decay_fa] = kdec_xfa * C_X[TComponents_Bio.X_fa];
       Kinetics[TReactions_bio_liq.decay_h2] = kdec_xh2 * C_X[TComponents_Bio.X_h2];
       Kinetics[TReactions_bio_liq.decay_pro] = kdec_xpro * C_X[TComponents_Bio.X_pro];
       Kinetics[TReactions_bio_liq.decay_su] = kdec_xsu * C_X[TComponents_Bio.X_su];
       Kinetics[TReactions_bio_liq.decay_srb_ac] = kdec_xsrbac * C_X[TComponents_Bio.X_srb_ac];
       Kinetics[TReactions_bio_liq.decay_srb_bu] = kdec_xsrbbu * C_X[TComponents_Bio.X_srb_bu];
       Kinetics[TReactions_bio_liq.decay_srb_pro] = kdec_xsrbpro * C_X[TComponents_Bio.X_srb_pro];
       Kinetics[TReactions_bio_liq.decay_srb_h] = kdec_xsrbh * C_X[TComponents_Bio.X_srb_h];
       Kinetics[TReactions_bio_liq.dis] = kdis * C_X[TComponents_Bio.X_c];
       Kinetics[TReactions_bio_liq.hyd_ch] = khyd_ch * C_X[TComponents_Bio.X_ch];
       Kinetics[TReactions_bio_liq.hyd_li] = khyd_li * C_X[TComponents_Bio.X_li];
       Kinetics[TReactions_bio_liq.hyd_pr] = khyd_pr * C_X[TComponents_Bio.X_pr];
       Kinetics[TReactions_bio_liq.uptake_aa] = km_aa * C_X[TComponents_Bio.X_aa] * C_S_Bio[TComponents_sol_Bio.S_aa] /(Ks_aa + C_S_Bio[TComponents_sol_Bio.S_aa]) * I_pH_bac * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_ac] = km_ac * C_X[TComponents_Bio.X_ac] * (BioIns[TComponents_Bio.Acetatemin]) / (Ks_ac + (BioIns[TComponents_Bio.Acetatemin])) * I_pH_ac * I_nh3_ac * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_bu] = km_c4 * C_X[TComponents_Bio.X_c4] * (BioIns[TComponents_Bio.Butyratemin]) / (Ks_c4 + (BioIns[TComponents_Bio.Butyratemin])) * (BioIns[TComponents_Bio.Butyratemin]) / ((BioIns[TComponents_Bio.Butyratemin]) + (BioIns[TComponents_Bio.Valeratemin]) + 0.000001) * I_pH_bac * I_h2_c4 * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_fa] = km_fa * C_X[TComponents_Bio.X_fa] * C_S_Bio[TComponents_sol_Bio.S_fa] / (Ks_fa + C_S_Bio[TComponents_sol_Bio.S_fa]) * I_pH_bac * I_h2_fa * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_h2] = km_h2 * C_X[TComponents_Bio.X_h2] * (BioIns[TComponents_Bio.H2]) / (Ks_h2 + (BioIns[TComponents_Bio.H2])) * I_pH_h2 * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_pro] = km_pro * (BioIns[TComponents_Bio.Propionatemin]) * (BioIns[TComponents_Bio.Propionatemin]) / (Ks_pro + (BioIns[TComponents_Bio.Propionatemin])) * I_pH_bac * I_h2_pro * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_su] = km_su * C_X[TComponents_Bio.X_su] * C_S_Bio[TComponents_sol_Bio.S_su] / (Ks_su + C_S_Bio[TComponents_sol_Bio.S_su]) * I_pH_bac * I_NH_limit;
       Kinetics[TReactions_bio_liq.uptake_va] = km_c4 * C_X[TComponents_Bio.X_c4] * (BioIns[TComponents_Bio.Valeratemin]) / (Ks_c4 + (BioIns[TComponents_Bio.Valeratemin])) * (BioIns[TComponents_Bio.Valeratemin]) / ((BioIns[TComponents_Bio.Valeratemin]) + (BioIns[TComponents_Bio.Butyratemin]) + 0.000001) * I_pH_bac * I_h2_c4 * I_NH_limit;
       Kinetics[TReactions_bio_liq.reduction_srb_bu] = km_srb_bu * ((BioIns[TComponents_Bio.Butyratemin]) / (Ks_srb_bu + BioIns[TComponents_Bio.Butyratemin])) * (BioIns[TComponents_Bio.SO4min2] / (Ks_so4_bu + BioIns[TComponents_Bio.SO4min2])) * I_pH_srb * I_h2s_bu * C_X[TComponents_Bio.X_srb_bu]; // Lizzeralde 
       Kinetics[TReactions_bio_liq.reduction_srb_pro] = km_srb_pro * (BioIns[TComponents_Bio.Propionatemin]  / (Ks_srb_pro + (BioIns[TComponents_Bio.Propionatemin] ))) * ((BioIns[TComponents_Bio.SO4min2])/ (Ks_so4_pro + (BioIns[TComponents_Bio.SO4min2]))) * I_pH_srb * I_h2s_pro * C_X[TComponents_Bio.X_srb_pro]; // Lizzeralde
       Kinetics[TReactions_bio_liq.reduction_srb_ac] = km_srb_ac * ((BioIns[TComponents_Bio.Acetatemin]) / (Ks_srb_ac + (BioIns[TComponents_Bio.Acetatemin]))) * ((BioIns[TComponents_Bio.SO4min2])/ (Ks_so4_ac + (BioIns[TComponents_Bio.SO4min2]))) * I_pH_srb * I_h2s_ac * C_X[TComponents_Bio.X_srb_ac]; // Lizzeralde 
       Kinetics[TReactions_bio_liq.reduction_srb_h] = km_srb_h2 * ((BioIns[TComponents_Bio.H2]) / (Ks_srb_h2 + (BioIns[TComponents_Bio.H2]))) * ((BioIns[TComponents_Bio.SO4min2]) / (Ks_so4_h2 + (BioIns[TComponents_Bio.SO4min2]))) * I_pH_srb * I_h2s_h2 * C_X[TComponents_Bio.X_srb_h]; // Lizzeralde 


    // Conversion term for biological reactions (kg COD/d) 
       Bioconversion = V_liq * (Kinetics * Stoichiometry); 
         
         
 // 8. MASS BALANCES

    // Physicochemical components in liquid phase (kmol/d)     
       for i in TComponents_sol_PC loop
           Transport_sol_PC[i] = (Q_liq_in * Ins[i] * 0.001) - Q_liq_out * C_S_PC[i] + 0.1 * C_S_PC[i]; 
           Transformation_sol_PC[i] = - TOut_prec_S[i] * V_liq - V_liq * TOut_gas_S[i] + Bioconversion_PC[i]; 
           der(M_S_PC[i]) = Transport_sol_PC[i] + Transformation_sol_PC[i]; 
       end for;
  
    // Biological components in liquid phase (kg COD/d)
       for i in TComponents_sol_Bio loop
           Transport_sol_Bio[i] = (Q_liq_in * BioIns_S[i]) - Q_liq_out * C_S_Bio[i]; 
           Transformation_sol_Bio[i] = Bioconversion[i]; 
           der(M_S_Bio[i]) = Transport_sol_Bio[i] + Transformation_sol_Bio[i]; 
       end for;  

    // Particulate biological components in liquid phase (kg COD/d)
       for i in TComponents_X_Bio loop
           Transport_X_Bio[i] = (Q_liq_in * BioIns_X[i]) - f_X_Out * Q_liq_out * C_X[i]; 
           Transformation_X_Bio[i] = Bioconversion[i]; 
           der(M_X[i]) = Transport_X_Bio[i] + Transformation_X_Bio[i]; 
       end for;   
 
    // Precipitated components (kmol/d)          
       for i in TComponents_P loop 
           Transport_prec[i] = (Q_liq_in * Ins_Prec[i]) - Q_liq_out * C_P[i]; 
           Transformation_prec[i] = TOut_prec_P[i] * V_liq; 
           der(M_P[i]) = Transport_prec[i] + Transformation_prec[i]; 
       end for;
       
    // Precipitated species (can be selected) (kmol/d)	
       der(M_P_Struvite) = V_liq * Kinetics_physchem[TReactions.Precip_Struvite] - Q_liq_out * C_P_Struvite; 
 
    // Gas phase components (kmol/d)          
       for i in TComponents_gas loop
           Transport_gas[i] = - Q_gas * C_gas[i]; 
           Transformation_gas[i] = V_liq * TOut_gas_G[i]; 
           der(M_gas[i]) = Transport_gas[i] + Transformation_gas[i]; 
       end for;    
 
    // COD balances for continuity (kg COD/d) 
       balance_COD_X = Q_liq_out * sum(M_X) / V_liq;
       balance_COD_S = Q_liq_out * (M_S_PC[TComponents_sol_PC.S_Valerate] * COD[TSpecies_PC_Bio.Valeratemin] + M_S_PC[TComponents_sol_PC.S_Butyrate] * COD[TSpecies_PC_Bio.Butyratemin] + M_S_PC[TComponents_sol_PC.S_Acetate] * COD[TSpecies_PC_Bio.Acetatemin] + M_S_PC[TComponents_sol_PC.S_Propionate] * COD[TSpecies_PC_Bio.Propionatemin] + sum(M_S_Bio)) / V_liq;  
    
    
 // 9. MEASUREMENTS 
    
    // Partial pressures and total pressure in the gas phase (atm)
       p = C_gas * R_Gas * T_op;
       p_h2o = 0.0313 * exp(5290 * ((1/T_op) - (1/298.15))); // cfr. ADM1
       p_headspace = sum(p) + p_h2o;   
       p_pc = p / p(sum) * 100; 
 
   
    // Gas flow (m3/d) 
       Q_gas = if (p_headspace  <= p_atm) then 0.0 else ((p_headspace - p_atm)^0.5 * K_p);
       QN_gas  = Q_gas  * p_headspace * (1.0 / p_atm);
   
  
 // 10. OUTPUTS  
    
    // Measurements
       pH_AD_PCB = Outs[TOut.pH]; 
       T_oper = T_op;
     
    // Gas flow
       p_Out = p; 
       p_h2o_Out = p_h2o;
       P_Biogas = p_headspace;
       Q_Biogas = Q_gas;
       p_out_pc = p_pc; 
     
    // Effluent and scaling potential 
       C_S_PC_Out = C_S_PC; 
       C_P_Out = C_P; 
       Total_X_COD_out =  balance_COD_X; 
       Total_S_COD_out =  balance_COD_S; 
       C_P_Struvite_out = C_P_Struvite; 
       Alkalinity_out = Outs[TOut.alkalinity];
 
   /* // Control
         Control = M_S_P + M_S_Ca + M_S_Mg + M_S_K + M_S_Al + M_S_Fe + M_S_Na + M_S_Cl + M_S_Nmin3 + M_S_N5 + M_S_N0 + M_S_S6 + M_S_Smin2 + M_S_C4 + M_S_Cmin4
                + M_S_Valerate + M_S_Butyrate + M_S_Acetate + M_S_Propionate + M_S_aa + M_S_fa + M_S_Inert + M_S_su + M_X_aa + M_X_ac + M_X_c + M_X_c4
                + M_X_ch + M_X_fa + M_X_h2 + M_X_Inert + M_X_li + M_X_pr + M_X_pro + M_X_su + M_X_srb_ac + M_X_srb_bu + M_X_srb_h + M_X_srb_pro 
                + M_ch4_gas + M_co2_gas + M_nh3_gas + M_h2s_gas + M_h2_gas + M_n2_gas + M_P_P + M_P_Ca + M_P_Mg + M_P_K + M_P_Al + M_P_Fe + M_P_Nmin3
                + M_P_C4 + M_P_Smin2 ; 
    */
 
// end Model;

/* References
- Arvidson R.S, Mackenzie F.D. (1999) The dolomite problem: Control of precipitation kinetics by temperature and saturation state. American Journal of Science, 299,  257-288.
- Batstone, D. J., J. Keller, I. Angelidaki, S. V. Kalyuzhnyi, S. G. Pavlostathis, A. Rozzi, W. T. M. Sanders, H. Siegrist & V. A. Vavilin (2002) The IWA Anaerobic Digestion Model No 1 (ADM1). Water Science and Technology, 45(10), 65-73.
- Bénézeth, P., D. A. Palmer & D. J. Wesolowski (2008) Dissolution/precipitation kinetics of boehmite and gibbsite: Application of a pH-relaxation technique to study near-equilibrium rates. Geochimica et Cosmochimica Acta, 72, 2429-2453. 
- Chapra, S. C. (2008) Surface water-quality modeling. Waveland Press Inc., Long Grove, Italy.
- Chauhan, C. K., P. M. Vyas & M. J. Joshi (2011) Growth and characterization of struvite-K crystals. Crystal Research and Technology, 46, 187-194. 
- Gujer, W. (2008) Systems analysis for water technology. Springer Verlag Berlin Heidelberg, Germany. 
  Grossl and Inskeep 1991, 
- Ikumi, D. S. (2011) The development of a three phase plant-wide mathematical model for sewage treatment. PhD 
  Thesis, Water Research Group, University of Cape Town, South Africa. 
- Johnson, M. L. (1990) Ferrous carbonate precipitation kinetics – A temperature ramped approach. PhD Thesis, Rice University, Houston, Texas, USA. 
- Lizarralde, I., M. de Gracia, L. Sancho, E. Ayesa & P. Grau (2010) New mathematical model for the treatment of wastewaters containing high sulphate concentration. 1st Spain National Young Water Professionals Conference, Conference Proceedings. Barcelona, Spain.- Knobel, A. N. & A. E. Lewis (2002) A mathematical model of a high sulphate wastewater anaerobic treatment system. Water Research, 36(1), 257-265. 
- Musvoto, E. V., M. C. Wentzel & G. A. Ekama (2000) Integrated chemical-physical processes modelling - II. Simulating aeration treatment of anaerobic digester supernatants. Water Research, 34, 1868-1880. 
- Morel and Hering (1993) Principles and Applications of Aquatic Chemistry. John Wiley and Sons, New York, US.
- Nielsen, A. E. (1984) Electrolyte crystal growth mechanisms. Journal of Crystal Growth, 67, 289-310. 
- Romanek, C. S., Morse, J. W.,  Grossman, E. L. (2011) Aragonite kinetics in dilute solutions Aquat Geochem, DOI10.1007/s10498-011-9127-2. 
- Sander, R. (1999) Compilation of Henry’s Law Constants for Inorganic and Organic Species of Potential Importance in Environmental Chemistry. 
  Report, Air Chemistry Department, Max-Planck Institute of Chemistry, Mainz, Germany. 
  Smits & Bleek (2013)  
- Sotemann, S. W., M. C. Wentzel & G. A. Ekama (2006) Mass balance based plant-wide wastewater treatment plant models – Part 4: Aerobic digestion of primary and waste activated sludges. Water SA, 32(3), 297-306. 
- Tchobanoglous, G., F. Burton & H. D. Stensel (2003) Metcalf & Eddy Wastewater Engineering: Treatment and Reuse. McGraw Hill, New York, USA. 
- Visual Minteq (2014) Vminteq31.  
*/ 

end PtG; 
