// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IEligibilityFilter {
    function tokenIsEligible(uint256) external view returns (bool);
    function eligibilityCriteria() external view returns (string memory);
}