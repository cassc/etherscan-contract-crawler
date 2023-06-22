// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.6;

/// @title   Interface of Multicall contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/IMulticall.sol
interface IMulticall {
    /// @notice          Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev             `msg.value` should not be trusted for any method callable from Multicall
    /// @param data      Encoded function data for each of the calls to make to this contract
    /// @return results  Results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}