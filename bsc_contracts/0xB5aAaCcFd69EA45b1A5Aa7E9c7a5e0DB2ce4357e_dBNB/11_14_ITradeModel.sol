// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;
//pragma experimental ABIEncoderV2;


interface ITradeModel {

    function iUSDrate(int _iUSDbalance, uint _availCash, uint _price) external pure returns(int rate);
    function cashAddUSDMinusLoss(int iUSDbalance, uint availCash, uint oraclePrice) external view returns(uint cashPlusUSD);
    function newRemoveLiquidityAmt(uint removeLiquidity, int _iUSDbalance, uint _availCash, uint _price) external view returns(uint newAmt);
    function getCashAddUSDMultAbsRate(int iUSDbalance, uint availCash, uint oraclePrice) external view returns(uint cashAddUSDMultUSDrate);
    function amountsOut(address _dTokenIn, address _dTokenOut, uint amountIn, uint oraclePrice, int iUSDbalance, uint availCash, uint traderBalanceXDP, address _referrer) external view returns(uint amountOut, uint reserveFeeUnderly, uint totalFeeAmt);

}