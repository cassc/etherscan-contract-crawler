// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IMiningIncentives {
    function totalStaked() external view returns (uint256);
    function stakedOf(address user) external view returns (uint256);
    function earned(address user) external view returns (uint256);
    function isOtherEarningsClaimable(address user) external view returns (bool);
    function esLBR() external view returns (address);
    function LBR() external view returns (address);
    function refreshReward(address _account) external;
}