// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGeminon.sol";
import "ICollectibleFees.sol";
import "IGeminonInfrastructure.sol";
import "ISCMinterMigration.sol";


interface ISCMinter is 
    IGeminon, 
    ICollectibleFees, 
    ISCMinterMigration, 
    IGeminonInfrastructure 
{

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++
    function USDI() external view returns(address);  
    function baseMintFee() external view returns(uint32);
    function baseRedeemFee() external view returns(uint32);
    function stablecoins(uint) external view returns(address);
    function validTokens(address) external view returns(bool);
    function mintedTokens(address) external view returns(bool);
    function baseSwapFees(address) external view returns(uint32);
    
    
    // ++++++++++++++++++++++++  INITIALIZATION  ++++++++++++++++++++++++++++
    function addStablecoin(address token, uint32 swapFee) external;
    function removeStablecoin(address token) external;

    // ++++++++++++++++++++++++++  PARAMETERS  +++++++++++++++++++++++++++++
    function setMintFee(uint32 value) external;
    function setRedeemFee(uint32 value) external;
    function setSwapFee(address stable, uint32 value) external;


    // ++++++++++++++++++++++++  USER FUNCTIONS  ++++++++++++++++++++++++++++
    function mintStablecoin(address stablecoin, uint256 inAmountGEX) external returns(uint256);
    function redeemStablecoin(address stablecoin, uint256 inAmountStablecoin) external returns(uint256);
    function stableSwap(address stableIn, address stableOut, uint256 amountIn) external returns(uint256);
    

    // ++++++++++++++++++++++  PROTOCOL FUNCTIONS  ++++++++++++++++++++++++++
    function pauseMint() external;
    function unpauseMint() external;    
    function addReservesGEX(uint256 amount) external;
    function addReserves(uint256 amount, address stablecoin) external;
    function burnReserves(uint256 amount, address stablecoin) external;
    function requestBailoutFromPool() external returns(uint256);
    
    
    // +++++++++++++++++++++  INFORMATIVE FUNCTIONS  ++++++++++++++++++++++++

    function getBalanceGEX() external view returns(uint256);
    function getTVC() external view returns(uint256);

    function amountFeeGEX(uint256 amountGEX, uint256 baseFee) external view returns(uint256 fee);
    function amountFeeMint(address stable, uint256 amountStable, uint256 usdPrice) external view returns(uint256);
    function amountFeeRedeem(address stable, uint256 amountStable, uint256 usdPrice) external view returns(uint256);
    function amountFeeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) external view returns(uint256);
    
    function feeStablecoinMint(address stable, uint256 amountStable) external view returns(uint256);
    function feeStablecoinRedeem(address stable, uint256 amountStable) external view returns(uint256);

    function amountUSDI(address stablecoin, uint256 amount) external view returns(uint256);
    function getMintInfo(uint256 inGEXAmount, address stablecoin) external view returns(
        uint256 gexPriceUSD,
        uint256 stablecoinPriceUSD, 
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    );
    function getRedeemInfo(uint256 inStablecoinAmount, address stablecoin) external view returns(
        uint256 stablecoinPriceUSD, 
        uint256 gexPriceUSD,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount
    );
    function getStableSwapInfo(uint256 inAmount, address stableIn, address stableOut) external view returns(
        uint256 inStablecoinPriceUSD,
        uint256 outStablecoinPriceUSD, 
        uint256 quoteS2S1,
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    );

    function amountMint(address stablecoin, uint256 amountGEX) external view returns(uint256);
    function amountRedeem(address stablecoin, uint256 amountStablecoin) external view returns(uint256);

    function getSafeMintRatio(address stablecoin) external view returns(uint256);
    function getSafeRedeemRatio(address stablecoin) external view returns(uint256);
    
    function feeGEX(uint256 amountGEX, uint256 baseFee) external view returns(uint256 fee);
    function feeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) external view returns(uint256);
}