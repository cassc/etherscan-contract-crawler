//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library MathLib {
    uint256 public constant WAD = 1e18;

    function mulWadDown(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        unchecked {
            c /= WAD;
        }
    }

    function divWadDown(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * WAD;
        unchecked {
            c /= b;
        }
    }

    function mulWadUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return mulArbUp(a, b, WAD);
    }

    function divWadUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return divArbUp(a, b, WAD);
    }

    function mulArbUp(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256) {
        return Math.ceilDiv(a * b, precision);
    }

    function divArbUp(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256) {
        return Math.ceilDiv(a * precision, b);
    }

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