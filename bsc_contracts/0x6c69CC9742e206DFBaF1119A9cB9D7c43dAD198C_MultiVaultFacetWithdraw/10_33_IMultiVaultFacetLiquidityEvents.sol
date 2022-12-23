// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidityEvents {
    event UpdateTokenLiquidityInterest(address token, uint interest);
    event UpdateDefaultLiquidityInterest(uint inetrest);

    event MintLiquidity(address sender, address token, uint amount, uint lp_amount);
    event RedeemLiquidity(address sender, address token, uint amount, uint underlying_amount);

    event EarnTokenCash(address token, uint amount);
}