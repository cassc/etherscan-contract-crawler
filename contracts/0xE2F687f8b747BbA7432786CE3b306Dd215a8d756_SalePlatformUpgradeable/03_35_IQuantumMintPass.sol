// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumMintPass {
    function burnFromRedeem(address user, uint256 mpId, uint256 amount) external;
}