// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct RoyaltyRecipient {
    bool isPaymentSplitter; // 1 byte
    uint16 bips; // 2 bytes
    address recipient; // 20 bytes
}