// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IMarketGeneration {
    function contribution(address) external view returns (uint256);
    function referralPoints(address) external view returns (uint256);    
    function totalContribution() external view returns (uint256);
    function totalReferralPoints() external view returns (uint256);
}