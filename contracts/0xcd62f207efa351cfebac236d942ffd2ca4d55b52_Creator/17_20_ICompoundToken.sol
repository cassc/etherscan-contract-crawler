// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ICompoundToken {
    function exchangeRateCurrent() external returns (uint256);

    /// @dev The address of the underlying asset
    function underlying() external view returns (address);
}