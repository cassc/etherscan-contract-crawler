// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Constants {
    enum Tier { bronze, silver, gold }
    bytes32 constant public SUPPORT_ROLE = keccak256("SUPPORT");
}