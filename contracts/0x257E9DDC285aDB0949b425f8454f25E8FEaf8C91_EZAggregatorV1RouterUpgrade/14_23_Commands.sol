// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Commands
/// @notice Command Flags used to decode commands
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x1f;
    bytes1 internal constant NFT_TYPE_MASK = 0x10;
    bytes1 internal constant SUB_IF_BRANCH_MASK = 0x08;

    // Command Types. Maximum supported command at this moment is 0x1F.

    // Command Types where value<0x08, executed in the first nested-if block
    uint256 constant RESERVOIR_Buy = 0x00;
    uint256 constant RESERVOIR_Sell = 0x01;
    uint256 constant WRAP_ETH = 0x02;
    uint256 constant UNWRAP_WETH = 0x03;
    uint256 constant SWEEP = 0x04;
    uint256 constant TRANSFER = 0x05;
    uint256 constant PAY_PORTION = 0x06;
    uint256 constant COMMAND_PLACEHOLDER_0x07 = 0x07;

    // Command Types where 0x08<=value<=0x0f, executed in the second nested-if block
    uint256 constant SUDOSWAP_Buy = 0x08;
    uint256 constant SUDOSWAP_Sell = 0x09;
    uint256 constant EZSWAP_Buy = 0x0a;
    uint256 constant EZSWAP_Sell = 0x0b;
    uint256 constant SWEEP_ERC721 = 0x0c;
    uint256 constant SWEEP_ERC1155 = 0x0d;
    uint256 constant COMMAND_PLACEHOLDER_0x0e = 0x0e;
    uint256 constant COMMAND_PLACEHOLDER_0x0f = 0x0f;

    // Command Types where 0x10<=value<0x18, executed in the third nested-if block
    uint256 constant COMMAND_PLACEHOLDER_0x10 = 0x10;
    uint256 constant COMMAND_PLACEHOLDER_0x11 = 0x11;
    uint256 constant COMMAND_PLACEHOLDER_0x12 = 0x12;
    uint256 constant COMMAND_PLACEHOLDER_0x13 = 0x13;
    uint256 constant COMMAND_PLACEHOLDER_0x14 = 0x14;
    uint256 constant COMMAND_PLACEHOLDER_0x15 = 0x15;
    uint256 constant COMMAND_PLACEHOLDER_0x16 = 0x16;
    uint256 constant COMMAND_PLACEHOLDER_0x17 = 0x17;

    // Command Types where 0x18<=value<=0x1f, executed in the final nested-if block
    uint256 constant COMMAND_PLACEHOLDER_0x18 = 0x18;
    uint256 constant COMMAND_PLACEHOLDER_0x19 = 0x19;
    uint256 constant COMMAND_PLACEHOLDER_0x1a = 0x1a;
    uint256 constant COMMAND_PLACEHOLDER_0x1b = 0x1b;
    uint256 constant COMMAND_PLACEHOLDER_0x1c = 0x1c;
    uint256 constant COMMAND_PLACEHOLDER_0x1d = 0x1d;
    uint256 constant COMMAND_PLACEHOLDER_0x1e = 0x1e;
    uint256 constant COMMAND_PLACEHOLDER_0x1f = 0x1f;

}