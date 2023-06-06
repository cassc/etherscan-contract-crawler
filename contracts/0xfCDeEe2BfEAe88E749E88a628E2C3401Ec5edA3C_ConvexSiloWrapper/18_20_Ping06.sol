// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.7.6; // solhint-disable-line compiler-version
pragma experimental ABIEncoderV2;

/// @notice Ping library for the older versions of Solidity.
library Ping06 {
    /// @notice Check if the target contract implements the expected ping function
    /// @param _target contract address
    /// @param _expectedSelector ping function that returns the value of it's own selector
    function pong(address _target, bytes4 _expectedSelector) internal view returns (bool) {
        (bool success, bytes memory data) = _target.staticcall(abi.encodeWithSelector(_expectedSelector));
        if (!success || data.length != 32) return false;

        bytes4 pingSelector = abi.decode(data, (bytes4));
        return pingSelector == _expectedSelector;
    }
}