// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IEulerToken {
    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    function convertBalanceToUnderlying(uint256)
        external
        view
        returns (uint256);

    /// @dev The address of the underlying asset
    function underlyingAsset() external view returns (address);
}