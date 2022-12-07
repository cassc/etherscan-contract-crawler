// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// General constant values

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10000;

/**
 * @dev Cap the number of royalty recipients.
 * A cap is required to ensure gas costs are not too high when a sale is settled.
 */
uint256 constant MAX_ROYALTY_RECIPIENTS = 5;

/**
 * @dev 100% in basis points.
 */
uint256 constant SPLIT_BASIS_POINTS = 100;

/**
 * @dev The minimum increase of 10% required when making an offer or placing a bid.
 */
uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1000;

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40000;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

/**
 * @dev Since ETH has no contract address, use address(0) as ETH Contract
 */
address constant CURRENCY_ETH = address(0);

/**
 * @dev Amount of ERC721 token is always constant.
 * Consider amount == 0 means token is ERC721
 * else, ERC1155
 */
uint256 constant ERC721_RESERVED_AMOUNT = 0;