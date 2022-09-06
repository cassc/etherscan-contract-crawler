// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/**
 * Bit manipulation made easy on 32 bytes slots represented by bytes32 primitives
 */
library BitOperation {
    function getBit(uint256 input_, uint8 index_) internal pure returns (bool) {
        return (input_ & (1 << index_)) != 0;
    }

    function clearBit(uint256 input_, uint8 index_) internal pure returns (uint256) {
        return input_ & ~(1 << index_);
    }

    function setBit(uint256 input_, uint8 index_) internal pure returns (uint256) {
        return input_ | (1 << index_);
    }

    function matchesMask(uint256 input_, uint256 mask_) internal pure returns (bool) {
        return (input_ & mask_) == mask_;
    }

    function negatesMask(uint256 input_, uint256 mask_) internal pure returns (bool) {
        return (input_ & mask_) == 0;
    }

    /// @notice Unpack a provided number into its composing powers of 2
    /// @dev Iteratively shift the number's binary representation to the right and check for the result parity
    /// @param packedNumber_ The number to decompose
    /// @return unpackedNumber The array of powers of 2 composing the number
    function unpackIn2Radix(uint256 packedNumber_) internal pure returns (uint256[] memory unpackedNumber) {
        // solhint-disable no-inline-assembly
        // Assembly is needed here to create a dynamic size array in memory instead of a storage one
        assembly {
            let currentPowerOf2 := 0

            // solhint-disable no-empty-blocks
            // This for loop is a while loop in disguise
            for {

            } gt(packedNumber_, 0) {
                // Increase the power of 2 by 1 after each iteration
                currentPowerOf2 := add(1, currentPowerOf2)
                // Shift the input to the right by 1
                packedNumber_ := shr(1, packedNumber_)
            } {
                // Check if the shifted input is odd
                if eq(and(1, packedNumber_), 1) {
                    // The shifted input is odd, let's add this power of 2 to the decomposition array
                    mstore(unpackedNumber, add(1, mload(unpackedNumber)))
                    mstore(add(unpackedNumber, mul(mload(unpackedNumber), 0x20)), currentPowerOf2)
                }
            }
            // Set the length of the decomposition array
            // Update the free memory pointer according to the decomposition array size
            mstore(0x40, add(unpackedNumber, mul(add(1, mload(unpackedNumber)), 0x20)))
        }
    }
}