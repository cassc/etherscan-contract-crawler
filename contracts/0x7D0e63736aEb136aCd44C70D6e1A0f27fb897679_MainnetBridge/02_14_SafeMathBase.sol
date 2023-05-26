// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

////
// NOTE: This has been edited to use OZ's SafeMath while
// preserving the ability to inherit from it.
// This is a shim to keep most of Chainbridge's code intact.
////

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * note that this is a stripped down version of open zeppelin's safemath
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 */

contract SafeMathBase {

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return SafeMath.sub(a, b);
    }

}