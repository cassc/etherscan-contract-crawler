// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IGrainSaleClaim {
    event Claim(address indexed user, uint256 value);
    function userShares(address user) external view returns (uint256, uint256, uint256);
    function cumulativeWeight() external view returns (uint256);
    function totalGrain() external view returns (uint256);
    function lgeEnd() external view returns (uint256);
}