// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../../math/FixedPointMath.sol";

/// @title OpFixedPointScale18Div
/// @notice Opcode for performing scale 18 fixed point division.
library OpFixedPointScale18Div {
    using FixedPointMath for uint256;

    function scale18Div(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        uint256 location_;
        uint256 a_;
        uint256 b_;
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            location_ := sub(stackTopLocation_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTopLocation_)
        }
        uint256 c_ = a_.scale18(operand_).fixedPointDiv(b_);
        assembly {
            mstore(location_, c_)
        }
        return stackTopLocation_;
    }
}