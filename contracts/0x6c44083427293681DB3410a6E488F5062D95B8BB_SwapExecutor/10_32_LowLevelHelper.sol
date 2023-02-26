// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

/**
 * @title LowLevelHelper
 * @notice Library for replacing uint256 by offset in calldata. Crucial for use cases like make a call with data from some previous call
 */
library LowLevelHelper {
    /// @notice offset should include 36 byte padding for selector and array length
    function patchUint(bytes calldata data, uint256 value, uint256 offset)
        internal
        pure
        returns (bytes memory result)
    {
        result = data;
        assembly {
            mstore(add(result, offset), value)
        }
    }
}