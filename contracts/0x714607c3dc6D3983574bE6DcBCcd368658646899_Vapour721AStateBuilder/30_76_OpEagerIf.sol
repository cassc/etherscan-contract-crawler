// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpEagerIf
/// @notice Opcode for selecting a value based on a condition.
library OpEagerIf {
    /// Eager because BOTH x_ and y_ must be eagerly evaluated
    /// before EAGER_IF will select one of them. If both x_ and y_
    /// are cheap (e.g. constant values) then this may also be the
    /// simplest and cheapest way to select one of them.
    function eagerIf(uint256, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            let location_ := sub(stackTopLocation_, 0x60)
            stackTopLocation_ := add(location_, 0x20)
            // false => use second value
            // true => use first value
            mstore(
                location_,
                mload(
                    add(stackTopLocation_, mul(0x20, iszero(mload(location_))))
                )
            )
        }
        return stackTopLocation_;
    }
}