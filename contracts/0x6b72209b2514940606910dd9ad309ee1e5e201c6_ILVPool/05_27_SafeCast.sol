// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity 0.8.4;

import { ErrorHandler } from "./ErrorHandler.sol";

/**
 * @notice Copied from OpenZeppelin's SafeCast.sol, adapted to use just in the required
 * uint sizes.
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    using ErrorHandler for bytes4;

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 _value) internal pure returns (uint248) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint248(uint256))"))`
        bytes4 fnSelector = 0x3fd72672;
        fnSelector.verifyInput(_value <= type(uint248).max, 0);

        return uint248(_value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 _value) internal pure returns (uint128) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint128(uint256))"))`
        bytes4 fnSelector = 0x809fdd33;
        fnSelector.verifyInput(_value <= type(uint128).max, 0);

        return uint128(_value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 _value) internal pure returns (uint120) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint120(uint256))"))`
        bytes4 fnSelector = 0x1e4e4bad;
        fnSelector.verifyInput(_value <= type(uint120).max, 0);

        return uint120(_value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 _value) internal pure returns (uint64) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint64(uint256))"))`
        bytes4 fnSelector = 0x2665fad0;
        fnSelector.verifyInput(_value <= type(uint64).max, 0);

        return uint64(_value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 _value) internal pure returns (uint32) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint32(uint256))"))`
        bytes4 fnSelector = 0xc8193255;
        fnSelector.verifyInput(_value <= type(uint32).max, 0);

        return uint32(_value);
    }
}