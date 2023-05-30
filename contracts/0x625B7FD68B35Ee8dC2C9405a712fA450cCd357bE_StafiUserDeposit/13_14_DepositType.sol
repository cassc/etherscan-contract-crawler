pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

// Represents the type of deposits
enum DepositType {
    None,    // Marks an invalid deposit type
    FOUR,    // Require 4 ETH from the node operator to be matched with 28 ETH from user deposits
    EIGHT,   // Require 8 ETH from the node operator to be matched with 24 ETH from user deposits
    TWELVE,  // Require 12 ETH from the node operator to be matched with 20 ETH from user deposits
    SIXTEEN,  // Require 16 ETH from the node operator to be matched with 16 ETH from user deposits
    Empty    // Require 0 ETH from the node operator to be matched with 32 ETH from user deposits (trusted nodes only)
}