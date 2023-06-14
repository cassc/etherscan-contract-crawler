// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { Math } from "openzeppelin-solidity/contracts/math/Math.sol";
import { SafeMath96 } from "./SafeMath96.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library MathHelpers {
    using SafeMath96 for uint96;
    using SafeMath for uint256;

    function proportion96(
        uint96 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint96) {
        return safe96(uint256(a).mul(b).div(c), "Amount exceeds 96 bits");
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function clamp96(
        uint96 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint96) {
        return safe96(Math.min(Math.max(a, b), c), "Amount exceeds 96 bits");
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}