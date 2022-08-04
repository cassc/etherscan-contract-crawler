// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../../math/FixedPointMath.sol";

/// @title OpFixedPointScaleBy
/// @notice Opcode for scaling a number by some OOMs.
library OpFixedPointScaleBy {
    using FixedPointMath for uint256;

    function scaleBy(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        uint256 location_;
        uint256 a_;
        assembly {
            location_ := sub(stackTopLocation_, 0x20)
            a_ := mload(location_)
        }
        uint256 b_ = a_.scaleBy(int8(uint8(operand_)));
        assembly {
            mstore(location_, b_)
        }
        return stackTopLocation_;
    }
}