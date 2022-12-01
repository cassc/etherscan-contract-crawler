// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWalletFactory {
    function createManagedVestingWallet(address beneficiary, address vestingManager) external returns (address);
}