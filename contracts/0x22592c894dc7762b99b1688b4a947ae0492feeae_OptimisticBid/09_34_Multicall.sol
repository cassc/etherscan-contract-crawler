// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data) external returns (bytes[] memory results) {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                // If there is return data and the call wasn't successful, the call reverted with a reason or a custom error.
                _revertedWithReason(result);
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles function for revert responses
    /// @param _response Reverted return response from a delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}