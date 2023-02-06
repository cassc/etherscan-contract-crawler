// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintpassVault {
    function claimWithMintpass(address to, uint256 amount) external;
    function mintableBalance() external view returns (uint256);
}