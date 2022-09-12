// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface ISCMinter is ICollectible {
    
    function receiveMigration(uint256 amountGEX) external;


    function mintStablecoin(address stablecoin, uint256 inAmountGEX) external ;

    function redeemStablecoin(address stablecoin, uint256 inAmountStablecoin) external;


    function getBalanceGEX() external view returns(uint256);

    function mintAmount(address stablecoin, uint256 amountGEX) external; 

    function redeemAmount(address stablecoin, uint256 amountStablecoin) external;

    function getSafeMintRatio(address stablecoin) external;

    function getSafeRedeemRatio(address stablecoin) external;
    

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}