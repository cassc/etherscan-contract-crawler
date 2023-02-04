//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library MathLib {
    /// Scales a value from a precision to another
    /// @param value value to be scaled
    /// @param fromPrecision param value precision on exponent form, e.g. 18 decimals -> 1e18
    /// @param toPrecision precision to scale value to on exponent form, e.g. 6 decimals -> 1e6
    /// @param roundCeiling whether to round ceiling or not when down scaling
    /// @return scaled value
    function scale(uint256 value, uint256 fromPrecision, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256 scaled)
    {
        if (fromPrecision > toPrecision) {
            uint256 adjustment = fromPrecision / toPrecision;
            scaled = roundCeiling ? Math.ceilDiv(value, adjustment) : value / adjustment;
        } else if (fromPrecision < toPrecision) {
            scaled = value * (toPrecision / fromPrecision);
        } else {
            scaled = value;
        }
    }
}