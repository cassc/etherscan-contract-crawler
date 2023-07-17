// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Managed index factory interface
/// @notice Provides method for index creation
interface IManagedIndexFactory is IIndexFactory {
    event ManagedIndexCreated(address index, address[] _assets, uint8[] _weights);

    /// @notice Create managed index with assets and their weights
    /// @param _assets Assets list for the index
    /// @param _weights List of assets corresponding weights. Assets total weight should be equal to 255
    /// @param _nameDetails Name details data (name and symbol) to use for the created index
    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external returns (address index);
}