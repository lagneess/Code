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
 * $Date: 6. marts 2014 16:42:13$
 *
 ******************************************************************************/
 
#ifndef __WWTP_ADM1_FUNCTIONS_H2_MO__
#define __WWTP_ADM1_FUNCTIONS_H2_MO__

package h2

// Functions

function Transport "Transport"
  input Real Q_in;
  input Real V_liq;
  input Real S_H_in;
  input Real S_H;
  output Real Result;
algorithm
  Result := Q_in / V_liq * (S_H_in - S_H);
end Transport;

function Sugar_Uptake "Uptake of Sugar"
  input Real Y_su;
  input Real f_h2_su;
  input Real rho_su;
  output Real Result;  
algorithm
  Result := (1 - Y_su) * f_h2_su * rho_su;
end Sugar_Uptake;

function AA_Uptake "Uptake of Amino Acids"
  input Real Y_aa;
  input Real f_h2_aa;
  input Real rho_aa;
  output Real Result;  
algorithm
  Result := (1 - Y_aa) * f_h2_aa * rho_aa;
end AA_Uptake;

function FA_Uptake "Update of LCFA"
  input Real Y_fa;
  input Real km_fa;
  input Real S_fa;
  input Real K_S_fa;
  input Real X_fa;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_fa;
  output Real Result;
algorithm
  Result := (1 - Y_fa) * 0.3 * km_fa * S_fa / (K_S_fa + S_fa) * X_fa * I_pH_aa * I_IN_lim / (1 + S_H / K_I_h2_fa);
end FA_Uptake;

function Va_Uptake "Uptake of Valerate"
  input Real Y_c4;
  input Real km_c4;
  input Real S_va;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_bu;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H; 
  input Real K_I_h2_c4;
  output Real Result;
algorithm
  Result := (1 - Y_c4) * 0.15 * km_c4 * S_va / (K_S_c4 + S_va) * X_c4 * S_va / (S_bu + S_va + 1e-6) * I_pH_aa * I_IN_lim / (1 + S_H / K_I_h2_c4);
end Va_Uptake;

function Bu_Uptake "Uptake of Butyrate"
  input Real Y_c4;
  input Real km_c4;
  input Real S_bu;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_va;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_c4;
  output Real Result;
algorithm
  Result := (1 - Y_c4) * 0.2 * km_c4 * S_bu / (K_S_c4 + S_bu) * X_c4 * S_bu / (S_bu + S_va + 1e-6) * I_pH_aa * I_IN_lim / (1 + S_H / K_I_h2_c4);
end Bu_Uptake;

function Pro_Uptake "Uptake of Propionate"
  input Real Y_pro;
  input Real km_pro;
  input Real S_pro;
  input Real K_S_pro;
  input Real X_pro;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_pro;
  output Real Result;
algorithm
  Result := (1 - Y_pro) * 0.43 * km_pro * S_pro / (K_S_pro + S_pro) * X_pro * I_pH_aa * I_IN_lim / (1 + S_H / K_I_h2_pro);
end Pro_Uptake;

function h2_Uptake "Uptake of hydrogen (S_H_ini introduced to avoid passing too many arguments; S_H_ini is the S_H passed by the function call"
  input Real km_h2;
  input Real S_H;
  input Real KS_h2;
  input Real X_h2;
  input Real I_pH_h2;
  input Real I_IN_lim;
  output Real Result;
algorithm
  Result := km_h2 * S_H / (KS_h2 + S_H) * X_h2 * I_pH_h2 * I_IN_lim;
end h2_Uptake;

function Transfer2Gas "Transfer to gas-phase"
  input Real kla;
  input Real S_H;
  input Real KH_h2;
  input Real p_gas_h2;
  output Real Result;
algorithm
  Result := kla * (S_H - 16 * KH_h2 * p_gas_h2);
end Transfer2Gas;

// Derivatives of functions

function D_FA_Uptake
  input Real Y_fa;
  input Real km_fa;
  input Real S_fa;
  input Real K_S_fa;
  input Real X_fa;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_fa;
  output Real Result;
algorithm
  Result := (1 - Y_fa) * 0.3 * km_fa * S_fa / (K_S_fa + S_fa) * X_fa * I_pH_aa * I_IN_lim * I_pH_aa * I_IN_lim * (-1 / (1 + S_H / K_I_h2_fa) / (1 + S_H / K_I_h2_fa) / K_I_h2_fa);
end D_FA_Uptake;

function D_Va_Uptake
  input Real Y_c4;
  input Real km_c4;
  input Real S_va;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_bu;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_c4;
  output Real Result;
algorithm
  Result := (1 - Y_c4) * 0.15 *  km_c4 * S_va / (K_S_c4 + S_va) * X_c4 * S_va / (S_bu + S_va + 1e-6) * I_pH_aa * I_IN_lim * (-1 / (1 + S_H / K_I_h2_c4) / (1 + S_H / K_I_h2_c4) / K_I_h2_c4);
end D_Va_Uptake;

function D_Bu_Uptake
  input Real Y_c4;
  input Real km_c4;
  input Real S_bu;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_va; 
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_c4;
  output Real Result;
algorithm
  Result := (1 - Y_c4) * 0.2 * km_c4 * S_bu / (K_S_c4 + S_bu) * X_c4 * S_bu / (S_bu + S_va + 1e-6) * I_pH_aa * I_IN_lim * (-1 / (1 + S_H / K_I_h2_c4) / (1 + S_H / K_I_h2_c4) / K_I_h2_c4);
end D_Bu_Uptake;

function D_Pro_Uptake
  input Real Y_pro;
  input Real km_pro;
  input Real S_pro;
  input Real K_S_pro;
  input Real X_pro;
  input Real I_pH_aa; 
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_pro;
  output Real Result;
algorithm
  Result := (1 - Y_pro) * 0.43 * km_pro * S_pro / (K_S_pro + S_pro) * X_pro * I_pH_aa * I_IN_lim * (-1 / (1 + S_H / K_I_h2_pro) / (1 + S_H / K_I_h2_pro) / K_I_h2_pro);
end D_Pro_Uptake;

function D_h2_Uptake
  input Real km_h2;
  input Real X_h2;
  input Real I_pH_h2;
  input Real I_IN_lim;
  input Real S_H;
  input Real KS_h2;
  output Real Result;
algorithm
  Result := km_h2 * X_h2 * I_pH_h2 * I_IN_lim * (1 / (KS_h2 + S_H) - S_H / (KS_h2 + S_H) / (KS_h2 + S_H));
end D_h2_Uptake;

// Functions needed for the Newton Raphson procedure

function f_h2 "Function evaluation of f(h2)"
  input Real Q_in;
  input Real V_liq;
  input Real S_H_in;
  input Real S_H;
  input Real Y_su;
  input Real f_h2_su;
  input Real rho_su;
  input Real Y_aa;
  input Real f_h2_aa;
  input Real rho_aa;
  input Real Y_fa;
  input Real km_fa;
  input Real S_fa;
  input Real K_S_fa;
  input Real X_fa;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real K_I_h2_fa;
  input Real Y_c4;
  input Real km_c4;
  input Real S_va;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_bu;
  input Real K_I_h2_c4;
  input Real Y_pro;
  input Real km_pro;
  input Real S_pro;
  input Real K_S_pro;
  input Real X_pro;  
  input Real K_I_h2_pro;
  input Real km_h2;
  input Real KS_h2;
  input Real X_h2;
  input Real I_pH_h2;
  input Real kla;
  input Real KH_h2;
  input Real p_gas_h2;
  output Real Result;
algorithm
  Result := Transport(Q_in, V_liq, S_H_in, S_H) 
            + Sugar_Uptake(Y_su, f_h2_su, rho_su) 
            + AA_Uptake(Y_aa, f_h2_aa, rho_aa)
            + FA_Uptake(Y_fa, km_fa, S_fa, K_S_fa, X_fa, I_pH_aa, I_IN_lim, S_H, K_I_h2_fa) 
            + Va_Uptake(Y_c4, km_c4, S_va, K_S_c4, X_c4, S_bu,I_pH_aa, I_IN_lim, S_H, K_I_h2_c4) 
            + Bu_Uptake(Y_c4, km_c4, S_bu, K_S_c4, X_c4, S_va, I_pH_aa, I_IN_lim, S_H, K_I_h2_c4)
            + Pro_Uptake(Y_pro, km_pro, S_pro, K_S_pro, X_pro, I_pH_aa, I_IN_lim, S_H, K_I_h2_pro)
            - h2_Uptake(km_h2, S_H, KS_h2, X_h2, I_pH_h2, I_IN_lim) 
            - Transfer2Gas(kla, S_H, KH_h2, p_gas_h2);
end f_h2;

function D_f_h2 "f'(h2)"
  input Real Q_in;
  input Real V_liq;
  input Real Y_fa;
  input Real km_fa;
  input Real S_fa;
  input Real K_S_fa;
  input Real X_fa;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real S_H;
  input Real K_I_h2_fa;
  input Real Y_c4;
  input Real km_c4;
  input Real S_va;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_bu;
  input Real K_I_h2_c4;
  input Real Y_pro;
  input Real km_pro;
  input Real S_pro;
  input Real K_S_pro;
  input Real X_pro;
  input Real K_I_h2_pro;
  input Real km_h2;
  input Real KS_h2;
  input Real X_h2;
  input Real I_pH_h2;
  input Real kla;
  output Real Result;
algorithm
  Result := (-Q_in/V_liq)
            + D_FA_Uptake(Y_fa, km_fa, S_fa, K_S_fa, X_fa, I_pH_aa, I_IN_lim, S_H, K_I_h2_fa)
            + D_Va_Uptake(Y_c4, km_c4, S_va, K_S_c4, X_c4, S_bu, I_pH_aa, I_IN_lim, S_H, K_I_h2_c4)
            + D_Bu_Uptake(Y_c4, km_c4, S_bu, K_S_c4, X_c4, S_va, I_pH_aa, I_IN_lim, S_H, K_I_h2_c4)
            + D_Pro_Uptake(Y_pro, km_pro, S_pro, K_S_pro, X_pro, I_pH_aa, I_IN_lim, S_H, K_I_h2_pro)
            - D_h2_Uptake(km_h2, X_h2, I_pH_h2, I_IN_lim, S_H,KS_h2) 
            - kla;
end D_f_h2;

function Compute
  input Real Q_in;
  input Real V_liq;
  input Real S_H_in;
  input Real S_H_ini;
  input Real Y_su;
  input Real f_h2_su;
  input Real rho_su;
  input Real Y_aa;
  input Real f_h2_aa;
  input Real rho_aa;
  input Real Y_fa;
  input Real km_fa;
  input Real S_fa;
  input Real K_S_fa;
  input Real X_fa;
  input Real I_pH_aa;
  input Real I_IN_lim;
  input Real K_I_h2_fa; 
  input Real Y_c4;
  input Real km_c4;
  input Real S_va;
  input Real K_S_c4;
  input Real X_c4;
  input Real S_bu;
  input Real K_I_h2_c4;
  input Real Y_pro;
  input Real km_pro;
  input Real S_pro;
  input Real K_S_pro;
  input Real X_pro;
  input Real K_I_h2_pro;
  input Real km_h2;
  input Real KS_h2;
  input Real X_h2;
  input Real I_pH_h2;
  input Real kla;
  input Real KH_h2;
  input Real p_gas_h2; 
  output Real S_H;  
  protected Real S_H0;
  protected Real f_SH;
  protected Integer i = 1;
  protected Boolean Continue = true;
  constant Real Tolerance = 1e-12;
  constant Integer MaxSteps = 1000;
algorithm
  S_H0 := S_H_ini;
  while Continue loop
    f_SH := f_h2(Q_in, V_liq, S_H_in, S_H0, Y_su, f_h2_su, rho_su, Y_aa, f_h2_aa, rho_aa, Y_fa, km_fa, S_fa, K_S_fa, X_fa, I_pH_aa, I_IN_lim, K_I_h2_fa,
                 Y_c4, km_c4, S_va, K_S_c4, X_c4, S_bu, K_I_h2_c4, Y_pro, km_pro, S_pro, K_S_pro, X_pro, K_I_h2_pro, km_h2, KS_h2, X_h2, I_pH_h2,
                 kla, KH_h2, p_gas_h2);
    S_H := S_H0 - f_SH / D_f_h2(Q_in, V_liq, Y_fa, km_fa, S_fa, K_S_fa, X_fa, I_pH_aa, I_IN_lim, S_H0, K_I_h2_fa, Y_c4, km_c4, S_va, K_S_c4, X_c4,
                                S_bu, K_I_h2_c4, Y_pro, km_pro, S_pro, K_S_pro, X_pro, K_I_h2_pro, km_h2, KS_h2, X_h2, I_pH_h2, kla);
    if (S_H <= 0) then
      S_H := 1e-12;
    end if;
    S_H0 := S_H;
    Continue := (abs(f_SH) > Tolerance) and (i <= MaxSteps);
    i := i + 1;   
  end while;  
end Compute;

end h2;

#endif