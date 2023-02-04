//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library MathLib {
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