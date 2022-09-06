// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../tier/libraries/TierwiseCombine.sol";

/// @title OpSelectLte
/// @notice Exposes `TierwiseCombine.selectLte` as an opcode.
library OpSelectLte {
    function stackPops(uint256 operand_) internal pure returns (uint256) {
        unchecked {
            uint256 reportsLength_ = operand_ & 0x1F; // & 00011111
            require(reportsLength_ > 0, "BAD_OPERAND");
            return reportsLength_;
        }
    }

    // Stacks the result of a `selectLte` combinator.
    // All `selectLte` share the same stack and argument handling.
    // Takes the `logic_` and `mode_` from the `operand_` high bits.
    // `logic_` is the highest bit.
    // `mode_` is the 2 highest bits after `logic_`.
    // The other bits specify how many values to take from the stack
    // as reports to compare against each other and the block number.
    function selectLte(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        uint256 logic_ = operand_ >> 7;
        uint256 mode_ = (operand_ >> 5) & 0x3; // & 00000011
        uint256 reportsLength_ = operand_ & 0x1F; // & 00011111

        uint256 location_;
        uint256[] memory reports_ = new uint256[](reportsLength_);
        uint256 time_;
        assembly {
            location_ := sub(
                stackTopLocation_,
                mul(add(reportsLength_, 1), 0x20)
            )
            let maxCursor_ := add(location_, mul(reportsLength_, 0x20))
            for {
                let cursor_ := location_
                let i_ := 0
            } lt(cursor_, maxCursor_) {
                cursor_ := add(cursor_, 0x20)
                i_ := add(i_, 0x20)
            } {
                mstore(add(reports_, add(0x20, i_)), mload(cursor_))
            }
            time_ := mload(maxCursor_)
        }

        uint256 result_ = TierwiseCombine.selectLte(
            reports_,
            time_,
            logic_,
            mode_
        );
        assembly {
            mstore(location_, result_)
            stackTopLocation_ := add(location_, 0x20)
        }
        return stackTopLocation_;
    }
}