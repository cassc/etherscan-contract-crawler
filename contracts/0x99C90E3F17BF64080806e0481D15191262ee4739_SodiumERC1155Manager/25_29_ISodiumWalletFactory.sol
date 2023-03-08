// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISodiumWalletFactory {
    event WalletCreated(address indexed owner, address wallet);

    function createWallet(address borrower) external returns (address);
}