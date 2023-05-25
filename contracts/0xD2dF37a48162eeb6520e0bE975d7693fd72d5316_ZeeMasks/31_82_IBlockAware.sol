// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/// @notice The implementer contract will always know at which block it was created.
interface IBlockAware {
    /// @notice Get deployment block number.
    function getDeploymentBlockNumber() external view returns (uint256);
}