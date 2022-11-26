// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICampaignManager {
    function calculateFees(uint256 softCap, uint256 hardCap, address mintToken, bool createDistributionContract) external view returns (uint256, uint256);
}