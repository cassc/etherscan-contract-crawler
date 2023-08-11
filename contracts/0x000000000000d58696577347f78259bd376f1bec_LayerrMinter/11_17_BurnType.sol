// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Burn type that specifies the token will be burned with a contract call that reduces supply
uint256 constant BURN_TYPE_CONTRACT_BURN = 0;
/// @dev Burn type that specifies the token will be transferred to the 0x000...dead address without reducing supply
uint256 constant BURN_TYPE_SEND_TO_DEAD = 1;