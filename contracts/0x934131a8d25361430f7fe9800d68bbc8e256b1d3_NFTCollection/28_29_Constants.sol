// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

/// Constant values shared across mixins.

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10_000;

/**
 * @dev The default admin role defined by OZ ACL modules.
 */
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

////////////////////////////////////////////////////////////////
// Royalties & Take Rates
////////////////////////////////////////////////////////////////

/**
 * @dev The max take rate an exhibition can have.
 */
uint256 constant MAX_EXHIBITION_TAKE_RATE = 5_000;

/**
 * @dev Cap the number of royalty recipients.
 * A cap is required to ensure gas costs are not too high when a sale is settled.
 */
uint256 constant MAX_ROYALTY_RECIPIENTS = 5;

/**
 * @dev Default royalty cut paid out on secondary sales.
 * Set to 10% of the secondary sale.
 */
uint96 constant ROYALTY_IN_BASIS_POINTS = 1_000;

/**
 * @dev Reward paid to referrers when a sale is made.
 * Set to 1% of the sale amount. This 1% is deducted from the protocol fee.
 */
uint96 constant BUY_REFERRER_IN_BASIS_POINTS = 100;

/**
 * @dev 10%, expressed as a denominator for more efficient calculations.
 */
uint256 constant ROYALTY_RATIO = BASIS_POINTS / ROYALTY_IN_BASIS_POINTS;

/**
 * @dev 1%, expressed as a denominator for more efficient calculations.
 */
uint256 constant BUY_REFERRER_RATIO = BASIS_POINTS / BUY_REFERRER_IN_BASIS_POINTS;

////////////////////////////////////////////////////////////////
// Gas Limits
////////////////////////////////////////////////////////////////

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40_000;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210_000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20_000;

////////////////////////////////////////////////////////////////
// Collection Type Names
////////////////////////////////////////////////////////////////

/**
 * @dev The NFT collection type.
 */
string constant NFT_COLLECTION_TYPE = "NFT Collection";

/**
 * @dev The NFT drop collection type.
 */
string constant NFT_DROP_COLLECTION_TYPE = "NFT Drop Collection";

/**
 * @dev The NFT timed edition collection type.
 */
string constant NFT_TIMED_EDITION_COLLECTION_TYPE = "NFT Timed Edition Collection";

/**
 * @dev The NFT limited edition collection type.
 */
string constant NFT_LIMITED_EDITION_COLLECTION_TYPE = "NFT Limited Edition Collection";

////////////////////////////////////////////////////////////////
// Business Logic
////////////////////////////////////////////////////////////////

/**
 * @dev Limits scheduled start/end times to be less than 2 years in the future.
 */
uint256 constant MAX_SCHEDULED_TIME_IN_THE_FUTURE = 365 days * 2;

/**
 * @dev The minimum increase of 10% required when making an offer or placing a bid.
 */
uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1_000;

/**
 * @dev Protocol fee for edition mints in basis points.
 */
uint256 constant EDITION_PROTOCOL_FEE_IN_BASIS_POINTS = 500;

/**
 * @dev Hash of the edition type names.
 * This is precalculated in order to save gas on use.
 * `keccak256(abi.encodePacked(NFT_TIMED_EDITION_COLLECTION_TYPE))`
 */
bytes32 constant timedEditionTypeHash = 0xee2afa3f960e108aca17013728aafa363a0f4485661d9b6f41c6b4ddb55008ee;

bytes32 constant limitedEditionTypeHash = 0x7df1f68d01ab1a6ee0448a4c3fbda832177331ff72c471b12b0051c96742eef5;