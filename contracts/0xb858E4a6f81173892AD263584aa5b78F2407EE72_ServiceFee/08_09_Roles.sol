// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @dev Role for interceptor contracts
 */
bytes32 constant INTERCEPTOR_ROLE = keccak256("INTERCEPTOR");
/**
 * @dev Role for configration management.
 */
bytes32 constant MANAGER_ROLE = keccak256("MANAGER");
/**
 * @dev Role for singed, used by the main contract.
 */
bytes32 constant SIGNER_ROLE = keccak256("SIGNER");

/**
 * @dev Role for calling transfer delegator
 */
bytes32 constant DELEGATION_CALLER_ROLE = keccak256("DELEGATION_CALLER");

/**
 * @dev Role for xy3nft minter
 */
bytes32 constant MINTER_ROLE = keccak256("MINTER");

/**
 * @dev Role for those can call exchange contracts
 */
bytes32 constant EXCHANGE_CALLER_ROLE = keccak256("EXCHANGE_CALLER");

/**
 * @dev Role for those can be called by FlashTrade
 */
bytes32 constant FLASH_TRADE_CALLEE_ROLE = keccak256("FLASH_TRADE_CALLEE");