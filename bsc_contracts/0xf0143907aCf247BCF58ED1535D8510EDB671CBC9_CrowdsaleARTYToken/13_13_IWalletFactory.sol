// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWalletFactory {
    function createManagedVestingWallet(address beneficiary, address vestingManager) external returns (address);
    function walletFor(address beneficiary, address vestingManager, bool strict) external view returns (address);
}