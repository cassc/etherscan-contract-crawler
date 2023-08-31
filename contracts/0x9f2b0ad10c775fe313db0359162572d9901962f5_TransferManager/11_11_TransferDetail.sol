// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct TransferDetail {
    address fromDepositAccount;
    address recipient;
    address tokenAddress;
    uint256 amount;
}