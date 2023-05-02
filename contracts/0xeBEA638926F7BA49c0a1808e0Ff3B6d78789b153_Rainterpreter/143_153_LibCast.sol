// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title LibCast
/// @notice Additional type casting logic that the Solidity compiler doesn't
/// give us by default. A type cast (vs. conversion) is considered one where the
/// structure is unchanged by the cast. The cast does NOT (can't) check that the
/// input is a valid output, for example any integer MAY be cast to a function
/// pointer but almost all integers are NOT valid function pointers. It is the
/// calling context that MUST ensure the validity of the data, the cast will
/// merely retype the data in place, generally without additional checks.
/// As most structures in solidity have the same memory structure as a `uint256`
/// or fixed/dynamic array of `uint256` there are many conversions that can be
/// done with near zero or minimal overhead.
library LibCast {
    /// Retype an array of `uint256[]` to `address[]`.
    /// @param us_ The array of integers to cast to addresses.
    /// @return addresses_ The array of addresses cast from each integer.
    function asAddressesArray(uint256[] memory us_) internal pure returns (address[] memory addresses_) {
        assembly ("memory-safe") {
            addresses_ := us_
        }
    }

    function asUint256Array(address[] memory addresses_) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := addresses_
        }
    }

    /// Retype an array of `uint256[]` to `bytes32[]`.
    /// @param us_ The array of integers to cast to 32 byte words.
    /// @return b32s_ The array of 32 byte words.
    function asBytes32Array(uint256[] memory us_) internal pure returns (bytes32[] memory b32s_) {
        assembly ("memory-safe") {
            b32s_ := us_
        }
    }

    function asUint256Array(bytes32[] memory b32s_) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := b32s_
        }
    }
}