// SPDX-License-Identifier: BSD-3-Clause
// SPDX-FileCopyrightText: Copyright 2020 Venus Labs, Inc.
pragma solidity ^0.5.16;
//pragma experimental ABIEncoderV2;


interface ITradeModel {

    function iUSDrate(int _iUSDbalance, uint _availCash, uint _price) external pure returns(int rate);
    function cashAddUSDMinusLoss(int iUSDbalance, uint availCash, uint oraclePrice) external view returns(uint cashPlusUSD);
    function newRemoveLiquidityAmt(uint removeLiquidity, int _iUSDbalance, uint _availCash, uint _price) external view returns(uint newAmt);
    function getCashAddUSDMultAbsRate(int iUSDbalance, uint availCash, uint oraclePrice) external view returns(uint cashAddUSDMultUSDrate);
    function amountsOut(address _dTokenIn, address _dTokenOut, uint amountIn, uint oraclePrice, int iUSDbalance, uint availCash, uint traderBalanceXDP) external view returns(uint amountOut, uint reserveFeeUnderly, uint totalFeeAmt);

}