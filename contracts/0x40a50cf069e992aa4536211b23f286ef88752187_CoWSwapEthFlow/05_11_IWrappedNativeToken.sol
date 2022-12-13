// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/IERC20.sol";

/// @title CoW Swap Wrapped Native Token Interface
/// @author CoW Swap Developers
interface IWrappedNativeToken is IERC20 {
    /// @dev Deposit native token in exchange for wrapped netive tokens.
    function deposit() external payable;

    /// @dev Burn wrapped native tokens in exchange for native tokens.
    /// @param amount Amount of wrapped tokens to exchange for native tokens.
    function withdraw(uint256 amount) external;
}