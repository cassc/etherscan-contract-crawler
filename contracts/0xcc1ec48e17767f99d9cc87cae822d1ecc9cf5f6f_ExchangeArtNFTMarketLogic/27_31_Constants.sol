// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10_000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20_000;

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40_000;

uint256 constant EXCHANGE_ART_PRIMARY_FEE = 500;

uint256 constant EXCHANGE_ART_SECONDARY_FEE = 250;