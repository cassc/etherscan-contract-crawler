//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFeeManager {
    function feeAddress() external view returns (address);
    function platformFee() external view returns (uint256);
    function rewardsFee() external view returns (uint256);
    function tradeFee() external view returns (uint256);
    function matureFee() external view returns (uint256);

    function rewardsAddress() external view returns (address);
    function rewardDistributor() external view returns (address);
}