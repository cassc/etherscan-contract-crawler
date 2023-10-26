// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedMulticall();

    struct CallData {
        address target;
        bytes callData;
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Allow trusted caller to call specified addresses through the Contract
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param calls The encoded function data and target for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via calls
    function extMulticall(CallData[] calldata calls) external returns (bytes[] memory);
}