// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Fallback Interface - Interface of the fallback method.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolFallback {
    /// @notice Delegate calls to pool extension.
    /// @dev Delegatecall restricted to owner, staticcall accessible by everyone.
    /// @dev Restricting delegatecall to owner effectively locks direct calls.
    fallback() external payable;

    /// @notice Allows transfers to pool.
    /// @dev Prevents accidental transfer to implementation contract.
    receive() external payable;
}