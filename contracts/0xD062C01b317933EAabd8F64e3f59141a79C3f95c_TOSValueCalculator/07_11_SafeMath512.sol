// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library SafeMath512 {


    //https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1){
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    // function mulmod(uint x, uint y, uint k) internal pure returns (uint) {
    //     return (x * y) % k;
    // }

    function div512(uint256 a0, uint256 a1, uint256 b) internal pure returns (uint256 x0, uint256 x1){
        //https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65
        uint256 q = div256(b);
        uint256 r = mod256(b);
        uint256 t0 = 0;
        uint256 t1 = 0;

        while (a1 != 0) {
            (t0, t1) = mul512(a1, q);
            (x0, x1) = add512(x0, x1, t0, t1);
            (x0, x1) = mul512(a1, r);
            (a0, a1) = add512(t0, t1, a0, 0);
        }
        (x0, x1) = add512(r, 0, a1 / b, 0);
    }


    function div256(uint256 a ) internal pure returns (uint256 r ){
        require(a > 1);

        assembly {
            r := add(div(sub(0, a), a), 1)
        }
    }


    function mod256(uint256 a) internal pure returns (uint256 r){
        //https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65

        require(a != 0);
        assembly {
            r := mod(sub(0, a), a)
        }
    }


    function add512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (uint256 r0, uint256 r1){
        assembly {
            r0 := add(a0, b0)
            r1 := add(add(a1, b1), lt(r0, a0))
        }
    }

    function sub512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (uint256 r0, uint256 r1){
        assembly {
            r0 := sub(a0, b0)
            r1 := sub(sub(a1, b1), lt(a0, b0))
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}