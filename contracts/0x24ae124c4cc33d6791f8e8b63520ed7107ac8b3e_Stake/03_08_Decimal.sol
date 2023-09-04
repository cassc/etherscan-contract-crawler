/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @notice Library that defines a fixed-point number with 18 decimal places.
 *
 * audit-info: Extended from dYdX's Decimal library:
 *             https://github.com/dydxprotocol/solo/blob/master/contracts/protocol/lib/Decimal.sol
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    /**
     * @notice Fixed-point base for Decimal.D256 values
     */
    uint256 constant BASE = 10**18;

    // ============ Structs ============


    /**
     * @notice Main struct to hold Decimal.D256 state
     * @dev Represents the number value / BASE
     */
    struct D256 {
        /**
         * @notice Underlying value of the Decimal.D256
         */
        uint256 value;
    }

    // ============ Static Functions ============

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 0.0
     * @return Decimal.D256 representation of 0.0
     */
    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 1.0
     * @return Decimal.D256 representation of 1.0
     */
    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a`
     * @param a Integer to transform to Decimal.D256 type
     * @return Decimal.D256 representation of integer`a`
     */
    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a` / `b`
     * @param a Numerator of ratio to transform to Decimal.D256 type
     * @param b Denominator of ratio to transform to Decimal.D256 type
     * @return Decimal.D256 representation of ratio `a` / `b`
     */
    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    /**
     * @notice Adds integer `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to add to `self`
     * @return Resulting Decimal.D256
     */
    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        uint256 amount = b.mul(BASE);
        return D256({ value: self.value > amount ? self.value.sub(amount) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to multiply `self` by
     * @return Resulting Decimal.D256
     */
    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b, reason) });
    }

    /**
     * @notice Exponentiates Decimal.D256 `self` to the power of integer `b`
     * @dev Not optimized - is only suitable to use with small exponents
     * @param self Original Decimal.D256 number
     * @param b Integer exponent
     * @return Resulting Decimal.D256
     */
    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    /**
     * @notice Adds Decimal.D256 `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to add to `self`
     * @return Resulting Decimal.D256
     */
    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value > b.value ? self.value.sub(b.value) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to multiply `self` by
     * @return Resulting Decimal.D256
     */
    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value, reason) });
    }

    /**
     * @notice Checks if `b` is equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is equal to `self`
     */
    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    /**
     * @notice Checks if `b` is greater than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than `self`
     */
    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    /**
     * @notice Checks if `b` is less than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than `self`
     */
    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    /**
     * @notice Checks if `b` is greater than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than or equal to `self`
     */
    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    /**
     * @notice Checks if `b` is less than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than or equal to `self`
     */
    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    /**
     * @notice Checks if `self` is equal to 0
     * @param self Original Decimal.D256 number
     * @return Whether `self` is equal to 0
     */
    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    /**
     * @notice Truncates the decimal part of `self` and returns the integer value as a uint256
     * @param self Original Decimal.D256 number
     * @return Truncated Integer value as a uint256
     */
    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ General Math ============

    /**
     * @notice Determines the minimum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting minimum Decimal.D256
     */
    function min(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return lessThan(a, b) ? a : b;
    }

    /**
     * @notice Determines the maximum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting maximum Decimal.D256
     */
    function max(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return greaterThan(a, b) ? a : b;
    }

    // ============ Core Methods ============

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @return Resulting Decimal.D256 number
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     *      Reverts on divide-by-zero with reason `reason`
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @param reason Revert reason
     * @return Resulting Decimal.D256 number
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator,
        string memory reason
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator, reason);
    }

    /**
     * @notice Compares Decimal.D256 `a` to Decimal.D256 `b`
     * @dev Internal only - helper
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return 0 if a < b, 1 if a == b, 2 if a > b
     */
    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}