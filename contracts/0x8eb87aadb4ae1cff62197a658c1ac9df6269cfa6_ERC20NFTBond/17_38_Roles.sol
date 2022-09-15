// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

bytes32 constant DEFAULT_ADMIN_ROLE = bytes32(0);

bytes32 constant INTEREST_PARAMETERS_SETTER  = keccak256("INTEREST_PARAMETERS_SETTER");
bytes32 constant COLLATERAL_BOND_SETTER  = keccak256("COLLATERAL_BOND_SETTER");
bytes32 constant LIQUIDITY_REQUESTER  = keccak256("LIQUIDITY_REQUESTER");
bytes32 constant PAUSER  = keccak256("PAUSER");
bytes32 constant UPGRADER  = keccak256("UPGRADER");
bytes32 constant MINTER = keccak256("MINTER");