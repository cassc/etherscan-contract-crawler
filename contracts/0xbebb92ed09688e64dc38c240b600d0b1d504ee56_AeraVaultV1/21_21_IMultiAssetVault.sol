// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Multi-asset vault interface.
interface IMultiAssetVault {
    /// @notice Balance of token with given index.
    /// @return Token balance in underlying pool.
    function holding(uint256 index) external view returns (uint256);

    /// @notice Underlying token balances.
    /// @return Token balances in underlying pool
    function getHoldings() external view returns (uint256[] memory);
}