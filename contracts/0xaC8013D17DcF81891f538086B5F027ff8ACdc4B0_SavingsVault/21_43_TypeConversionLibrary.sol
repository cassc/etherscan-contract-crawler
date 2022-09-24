// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

library TypeConversionLibrary {
    /// @notice Safe downcast from uint256 to uint88
    /// @param _x value to downcast
    function _safeUint88(uint256 _x) internal pure returns (uint88) {
        require(_x <= uint256(type(uint88).max), "TypeConversionLibrary: OVERFLOW");
        return uint88(_x);
    }

    /// @notice Safe downcast from uint256 to uint32
    /// @param _x value to downcast
    function _safeUint32(uint256 _x) internal pure returns (uint32) {
        require(_x <= uint256(type(uint32).max), "TypeConversionLibrary: OVERFLOW");
        return uint32(_x);
    }
}