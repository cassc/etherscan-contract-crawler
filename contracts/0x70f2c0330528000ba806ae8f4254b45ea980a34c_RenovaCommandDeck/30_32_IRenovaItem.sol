// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './IRenovaItemBase.sol';

/// @title IRenovaItem
/// @author Victor Ionescu
/// @notice See {IRenovaItemBase}
/// @dev Deployed on the main chain.
interface IRenovaItem is IRenovaItemBase {
    /// @notice Emitted when the authorization status of a minter changes.
    /// @param minter The minter for which the status was updated.
    /// @param status The new status.
    event UpdateMinterAuthorization(address minter, bool status);

    /// @notice Initializer function.
    /// @param minter The initial authorized minter.
    /// @param wormhole The Wormhole Endpoint address. See {IWormholeBaseUpgradeable}.
    /// @param wormholeConsistencyLevel The Wormhole Consistency Level. See {IWormholeBaseUpgradeable}.
    function initialize(
        address minter,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) external;

    /// @notice Mints an item.
    /// @param tokenOwner The owner of the item.
    /// @param hashverseItemId The Hashverse Item ID.
    function mint(address tokenOwner, uint256 hashverseItemId) external;

    /// @notice Updates the authorization status of a minter.
    /// @param minter The minter to update the authorization status for.
    /// @param status The new status.
    function updateMinterAuthorization(address minter, bool status) external;
}