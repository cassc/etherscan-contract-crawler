// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Payee {
    address account;
    uint32 shares;
    bool transfersAllowedWhileLocked;
}