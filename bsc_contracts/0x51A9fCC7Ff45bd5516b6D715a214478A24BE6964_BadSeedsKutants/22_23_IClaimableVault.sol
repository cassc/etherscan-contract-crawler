// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClaimableVault {
    function claim(address to, uint256 amount) external;
    function claimableBalance() external view returns (uint256);
}