// SPDX-License-Identifier: Apache-2.0

/*
    Original version by Synthetix.io
    https://docs.synthetix.io/contracts/source/libraries/safedecimalmath

    Adapted by Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

// solhint-disable

/**
 * @notice Forked from https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/lib/helpers/BalancerErrors.sol
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAB#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAB#" part is a known constant
        // (0x42414223): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414223000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Max deposit limit needs to be under the limit
    uint256 internal constant MAX_DEPOSIT_LIMIT = 0;
    // Creator needs to deposit
    uint256 internal constant MIN_CONTRIBUTION = 1;
    // Min Garden token supply >= 0
    uint256 internal constant MIN_TOKEN_SUPPLY = 2;
    // Deposit hardlock needs to be at least 1 block
    uint256 internal constant DEPOSIT_HARDLOCK = 3;
    // Needs to be at least the minimum
    uint256 internal constant MIN_LIQUIDITY = 4;
    // _reserveAssetQuantity is not equal to msg.value
    uint256 internal constant MSG_VALUE_DO_NOT_MATCH = 5;
    // Withdrawal amount has to be equal or less than msg.sender balance
    uint256 internal constant MSG_SENDER_TOKENS_DO_NOT_MATCH = 6;
    // Tokens are staked
    uint256 internal constant TOKENS_STAKED = 7;
    // Balance too low
    uint256 internal constant BALANCE_TOO_LOW = 8;
    // msg.sender doesn't have enough tokens
    uint256 internal constant MSG_SENDER_TOKENS_TOO_LOW = 9;
    //  There is an open redemption window already
    uint256 internal constant REDEMPTION_OPENED_ALREADY = 10;
    // Cannot request twice in the same window
    uint256 internal constant ALREADY_REQUESTED = 11;
    // Rewards and profits already claimed
    uint256 internal constant ALREADY_CLAIMED = 12;
    // Value have to be greater than zero
    uint256 internal constant GREATER_THAN_ZERO = 13;
    // Must be reserve asset
    uint256 internal constant MUST_BE_RESERVE_ASSET = 14;
    // Only contributors allowed
    uint256 internal constant ONLY_CONTRIBUTOR = 15;
    // Only controller allowed
    uint256 internal constant ONLY_CONTROLLER = 16;
    // Only creator allowed
    uint256 internal constant ONLY_CREATOR = 17;
    // Only keeper allowed
    uint256 internal constant ONLY_KEEPER = 18;
    // Fee is too high
    uint256 internal constant FEE_TOO_HIGH = 19;
    // Only strategy allowed
    uint256 internal constant ONLY_STRATEGY = 20;
    // Only active allowed
    uint256 internal constant ONLY_ACTIVE = 21;
    // Only inactive allowed
    uint256 internal constant ONLY_INACTIVE = 22;
    // Address should be not zero address
    uint256 internal constant ADDRESS_IS_ZERO = 23;
    // Not within range
    uint256 internal constant NOT_IN_RANGE = 24;
    // Value is too low
    uint256 internal constant VALUE_TOO_LOW = 25;
    // Value is too high
    uint256 internal constant VALUE_TOO_HIGH = 26;
    // Only strategy or protocol allowed
    uint256 internal constant ONLY_STRATEGY_OR_CONTROLLER = 27;
    // Normal withdraw possible
    uint256 internal constant NORMAL_WITHDRAWAL_POSSIBLE = 28;
    // User does not have permissions to join garden
    uint256 internal constant USER_CANNOT_JOIN = 29;
    // User does not have permissions to add strategies in garden
    uint256 internal constant USER_CANNOT_ADD_STRATEGIES = 30;
    // Only Protocol or garden
    uint256 internal constant ONLY_PROTOCOL_OR_GARDEN = 31;
    // Only Strategist
    uint256 internal constant ONLY_STRATEGIST = 32;
    // Only Integration
    uint256 internal constant ONLY_INTEGRATION = 33;
    // Only garden and data not set
    uint256 internal constant ONLY_GARDEN_AND_DATA_NOT_SET = 34;
    // Only active garden
    uint256 internal constant ONLY_ACTIVE_GARDEN = 35;
    // Contract is not a garden
    uint256 internal constant NOT_A_GARDEN = 36;
    // Not enough tokens
    uint256 internal constant STRATEGIST_TOKENS_TOO_LOW = 37;
    // Stake is too low
    uint256 internal constant STAKE_HAS_TO_AT_LEAST_ONE = 38;
    // Duration must be in range
    uint256 internal constant DURATION_MUST_BE_IN_RANGE = 39;
    // Duplicated strategies
    uint256 internal constant DUPLICATED_STRATEGIES = 40;
    // Max Capital Requested
    uint256 internal constant MAX_CAPITAL_REQUESTED = 41;
    // Votes are already resolved
    uint256 internal constant VOTES_ALREADY_RESOLVED = 42;
    // Voting window is closed
    uint256 internal constant VOTING_WINDOW_IS_OVER = 43;
    // Strategy needs to be active
    uint256 internal constant STRATEGY_NEEDS_TO_BE_ACTIVE = 44;
    // Max capital reached
    uint256 internal constant MAX_CAPITAL_REACHED = 45;
    // Capital is less then rebalance
    uint256 internal constant CAPITAL_IS_LESS_THAN_REBALANCE = 46;
    // Strategy is in cooldown period
    uint256 internal constant STRATEGY_IN_COOLDOWN = 47;
    // Strategy is not executed
    uint256 internal constant STRATEGY_IS_NOT_EXECUTED = 48;
    // Strategy is not over yet
    uint256 internal constant STRATEGY_IS_NOT_OVER_YET = 49;
    // Strategy is already finalized
    uint256 internal constant STRATEGY_IS_ALREADY_FINALIZED = 50;
    // No capital to unwind
    uint256 internal constant STRATEGY_NO_CAPITAL_TO_UNWIND = 51;
    // Strategy needs to be inactive
    uint256 internal constant STRATEGY_NEEDS_TO_BE_INACTIVE = 52;
    // Duration needs to be less
    uint256 internal constant DURATION_NEEDS_TO_BE_LESS = 53;
    // Can't sweep reserve asset
    uint256 internal constant CANNOT_SWEEP_RESERVE_ASSET = 54;
    // Voting window is opened
    uint256 internal constant VOTING_WINDOW_IS_OPENED = 55;
    // Strategy is executed
    uint256 internal constant STRATEGY_IS_EXECUTED = 56;
    // Min Rebalance Capital
    uint256 internal constant MIN_REBALANCE_CAPITAL = 57;
    // Not a valid strategy NFT
    uint256 internal constant NOT_STRATEGY_NFT = 58;
    // Garden Transfers Disabled
    uint256 internal constant GARDEN_TRANSFERS_DISABLED = 59;
    // Tokens are hardlocked
    uint256 internal constant TOKENS_HARDLOCKED = 60;
    // Max contributors reached
    uint256 internal constant MAX_CONTRIBUTORS = 61;
    // BABL Transfers Disabled
    uint256 internal constant BABL_TRANSFERS_DISABLED = 62;
    // Strategy duration range error
    uint256 internal constant DURATION_RANGE = 63;
    // Checks the min amount of voters
    uint256 internal constant MIN_VOTERS_CHECK = 64;
    // Ge contributor power error
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_WINDOW = 65;
    // Not enough reserve set aside
    uint256 internal constant NOT_ENOUGH_RESERVE = 66;
    // Garden is already public
    uint256 internal constant GARDEN_ALREADY_PUBLIC = 67;
    // Withdrawal with penalty
    uint256 internal constant WITHDRAWAL_WITH_PENALTY = 68;
    // Withdrawal with penalty
    uint256 internal constant ONLY_MINING_ACTIVE = 69;
    // Overflow in supply
    uint256 internal constant OVERFLOW_IN_SUPPLY = 70;
    // Overflow in power
    uint256 internal constant OVERFLOW_IN_POWER = 71;
    // Not a system contract
    uint256 internal constant NOT_A_SYSTEM_CONTRACT = 72;
    // Strategy vs Garden mismatch
    uint256 internal constant STRATEGY_GARDEN_MISMATCH = 73;
    // Minimum quarters is 1
    uint256 internal constant QUARTERS_MIN_1 = 74;
    // Too many strategy operations
    uint256 internal constant TOO_MANY_OPS = 75;
    // Only operations
    uint256 internal constant ONLY_OPERATION = 76;
    // Strat params wrong length
    uint256 internal constant STRAT_PARAMS_LENGTH = 77;
    // Garden params wrong length
    uint256 internal constant GARDEN_PARAMS_LENGTH = 78;
    // Token names too long
    uint256 internal constant NAME_TOO_LONG = 79;
    // Contributor power overflows over garden power
    uint256 internal constant CONTRIBUTOR_POWER_OVERFLOW = 80;
    // Contributor power window out of bounds
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_DEPOSITS = 81;
    // Contributor power window out of bounds
    uint256 internal constant NO_REWARDS_TO_CLAIM = 82;
    // Pause guardian paused this operation
    uint256 internal constant ONLY_UNPAUSED = 83;
    // Reentrant intent
    uint256 internal constant REENTRANT_CALL = 84;
    // Reserve asset not supported
    uint256 internal constant RESERVE_ASSET_NOT_SUPPORTED = 85;
    // Withdrawal/Deposit check min amount received
    uint256 internal constant RECEIVE_MIN_AMOUNT = 86;
    // Total Votes has to be positive
    uint256 internal constant TOTAL_VOTES_HAVE_TO_BE_POSITIVE = 87;
    // Signer has to be valid
    uint256 internal constant INVALID_SIGNER = 88;
    // Nonce has to be valid
    uint256 internal constant INVALID_NONCE = 89;
    // Garden is not public
    uint256 internal constant GARDEN_IS_NOT_PUBLIC = 90;
    // Setting max contributors
    uint256 internal constant MAX_CONTRIBUTORS_SET = 91;
    // Profit sharing mismatch for customized gardens
    uint256 internal constant PROFIT_SHARING_MISMATCH = 92;
    // Max allocation percentage
    uint256 internal constant MAX_STRATEGY_ALLOCATION_PERCENTAGE = 93;
    // new creator must not exist
    uint256 internal constant NEW_CREATOR_MUST_NOT_EXIST = 94;
    // only first creator can add
    uint256 internal constant ONLY_FIRST_CREATOR_CAN_ADD = 95;
    // invalid address
    uint256 internal constant INVALID_ADDRESS = 96;
    // creator can only renounce in some circumstances
    uint256 internal constant CREATOR_CANNOT_RENOUNCE = 97;
    // no price for trade
    uint256 internal constant NO_PRICE_FOR_TRADE = 98;
    // Max capital requested
    uint256 internal constant ZERO_CAPITAL_REQUESTED = 99;
    // Unwind capital above the limit
    uint256 internal constant INVALID_CAPITAL_TO_UNWIND = 100;
    // Mining % sharing does not match
    uint256 internal constant INVALID_MINING_VALUES = 101;
    // Max trade slippage percentage
    uint256 internal constant MAX_TRADE_SLIPPAGE_PERCENTAGE = 102;
    // Max gas fee percentage
    uint256 internal constant MAX_GAS_FEE_PERCENTAGE = 103;
    // Mismatch between voters and votes
    uint256 internal constant INVALID_VOTES_LENGTH = 104;
    // Only Rewards Distributor
    uint256 internal constant ONLY_RD = 105;
    // Fee is too LOW
    uint256 internal constant FEE_TOO_LOW = 106;
    // Only governance or emergency
    uint256 internal constant ONLY_GOVERNANCE_OR_EMERGENCY = 107;
    // Strategy invalid reserve asset amount
    uint256 internal constant INVALID_RESERVE_AMOUNT = 108;
    // Heart only pumps once a week
    uint256 internal constant HEART_ALREADY_PUMPED = 109;
    // Heart needs garden votes to pump
    uint256 internal constant HEART_VOTES_MISSING = 110;
    // Not enough fees for heart
    uint256 internal constant HEART_MINIMUM_FEES = 111;
    // Invalid heart votes length
    uint256 internal constant HEART_VOTES_LENGTH = 112;
    // Heart LP tokens not received
    uint256 internal constant HEART_LP_TOKENS = 113;
    // Heart invalid asset to lend
    uint256 internal constant HEART_ASSET_LEND_INVALID = 114;
    // Heart garden not set
    uint256 internal constant HEART_GARDEN_NOT_SET = 115;
    // Heart asset to lend is the same
    uint256 internal constant HEART_ASSET_LEND_SAME = 116;
    // Heart invalid ctoken
    uint256 internal constant HEART_INVALID_CTOKEN = 117;
    // Price per share is wrong
    uint256 internal constant PRICE_PER_SHARE_WRONG = 118;
    // Heart asset to purchase is same
    uint256 internal constant HEART_ASSET_PURCHASE_INVALID = 119;
    // Reset hardlock bigger than timestamp
    uint256 internal constant RESET_HARDLOCK_INVALID = 120;
    // Invalid referrer
    uint256 internal constant INVALID_REFERRER = 121;
    // Only Heart Garden
    uint256 internal constant ONLY_HEART_GARDEN = 122;
    // Max BABL Cap to claim by sig
    uint256 internal constant MAX_BABL_CAP_REACHED = 123;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_BABL = 124;
    // Claim garden NFT
    uint256 internal constant CLAIM_GARDEN_NFT = 125;
    // Not enough collateral
    uint256 internal constant NOT_ENOUGH_COLLATERAL = 126;
    // Amount too low
    uint256 internal constant AMOUNT_TOO_LOW = 127;
    // Amount too high
    uint256 internal constant AMOUNT_TOO_HIGH = 128;
    // Not enough to repay debt
    uint256 internal constant SLIPPAGE_TOO_HIH = 129;
    // Invalid amount
    uint256 internal constant INVALID_AMOUNT = 130;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_AMOUNT = 131;
    // Error minting
    uint256 internal constant MINT_ERROR = 132;
    // Error no unlock signal needed
    uint256 internal constant NO_SIGNAL_NEEDED = 133;
    // Error setting garden user lock
    uint256 internal constant SET_GARDEN_USER_LOCK = 134;
    // Error setting garden user lock
    uint256 internal constant RARI_HACK_STRAT = 135;
    // Error setting whitelist
    uint256 internal constant ALREADY_WHITELISTED = 136;
    // Error whitelist over
    uint256 internal constant WHITELIST_OVER = 137;
    // Error claim period not started or over
    uint256 internal constant CLAIM_OVER = 138;
    // Error users not whitelisted
    uint256 internal constant NOT_WHITELISTED = 139;
    // Error users has no balance to be whitelisted
    uint256 internal constant NO_BALANCE_WHITELIST = 140;
    // Error liquidation amount not set
    uint256 internal constant LIQUIDATION_AMOUNT_NOT_SET = 141;
    // Error claim  not over
    uint256 internal constant CLAIM_NOT_OVER = 142;
    // Error refund tokens not set
    uint256 internal constant REFUND_TOKENS_NOT_SET = 143;
}