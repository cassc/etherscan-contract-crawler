// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Packing {
    /// @dev    This packs inputs into a bytes32
    /// @param  a      The first type to pack
    /// @param  b      The second type to pack
    /// @return retval The packed bytes32
    function addressUint96(address a, uint96 b) internal pure returns (bytes32 retval) {
        retval |= bytes32(bytes20(a)); // bits 0...159
        retval |= bytes32(bytes12(b)) >> 160; // bits 160...255
    }
}