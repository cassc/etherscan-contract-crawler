/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Interface for the Base contract inherited by Portals

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

interface IPortalBase {
    /// @notice Emitted when a portal is collected
    /// @param token The ERC20 token address to collect (address(0) if network token)
    /// @param amount The quantity of th token to collect
    event Collect(address token, uint256 amount);

    /// @notice Emitted when the fee is changed
    /// @param oldFee The ERC20 token address to collect (address(0) if network token)
    /// @param newFee The quantity of th token to collect
    event Fee(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when a portal is paused
    /// @param paused The active status of this contract. If false, contract is active (i.e un-paused)
    event Pause(bool paused);

    /// @notice Emitted when the registry is upated
    /// @param registry The address of the new registry
    event UpdateRegistry(address registry);
}