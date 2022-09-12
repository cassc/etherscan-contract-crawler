// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface IGenesisLiquidityPool is ICollectible {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function poolWeight() external view returns(uint16);
    
    function balanceCollateral() external view returns(uint256);

    function balanceGEX() external view returns(uint256);

    function mintedGEX() external view returns(int256);

    function meanPrice() external view returns(uint256);
    
    function lastPrice() external view returns(uint256);
    
    function meanVolume() external view returns(uint256);
    
    function lastVolume() external view returns(uint256);

    function isMigrationRequested() external view returns(bool);
    
    function isRemoveRequested() external view returns(bool);    
    

    // ++++++++++++++++++++++++++  MIGRATION  +++++++++++++++++++++++++++++++

    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount) external;

    function bailoutMinter() external returns(uint256);

    function lendCollateral(uint256 amount) external returns(uint256);

    function repayCollateral(uint256 amount) external returns(uint256);

    
    // ++++++++++++++++++++++++  USE FUNCTIONS  +++++++++++++++++++++++++++++
    
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external;

    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external;
    
    
    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function collateralPrice() external view returns(uint256);

    function collateralQuote() external view returns(uint256);

    function getCollateralValue() external view returns(uint256);

    function GEXPrice() external view returns(uint256);

    function GEXQuote() external view returns(uint256);

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function getMintInfo(uint256 inCollatAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function getRedeemInfo(uint256 inGEXAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function amountOutGEX(uint256 inCollatAmount) external view returns(uint256);

    function amountOutCollateral(uint256 inGEXAmount) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}