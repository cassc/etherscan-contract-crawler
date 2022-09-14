pragma solidity ^0.8.17;

/**
 * @dev Wrappers over Solidity's unsigned integer arithmetic operations with added overflow
 *  checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 *  in bugs, because programmers usually assume that an overflow raises an
 *  error, which is the standard behavior in high level programming languages.
 *  `SafeMath` restores this intuition by reverting the transaction when an
 *  operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 *  class of bugs, so it's recommended to use it always.
 */
// SPDX-License-Identifier: MIT
library SafeMathUInt {

    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }

}