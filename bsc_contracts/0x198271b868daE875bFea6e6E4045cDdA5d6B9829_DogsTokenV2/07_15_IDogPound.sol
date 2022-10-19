// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILoyalityPool {
    function totalTaxReduction(address _user, uint256 _stakeID) external view returns (uint256);
}