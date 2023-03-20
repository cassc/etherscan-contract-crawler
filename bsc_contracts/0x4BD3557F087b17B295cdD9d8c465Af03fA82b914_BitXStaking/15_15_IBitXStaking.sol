// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBitXStaking {
 function addReferral(address[] memory _referrals, address staker) external;
}