// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Asbtract "Ownable" contract managing a whitelist of factories
abstract contract OwnableFactoryHandler is Ownable {
    /// @dev Emitted when a new factory is added
    /// @param newFactory Address of the new factory
    event FactoryAdded(address newFactory);

    /// @dev Emitted when a factory is removed
    /// @param oldFactory Address of the removed factory
    event FactoryRemoved(address oldFactory);

    /// @dev Supported factories to interact with
    mapping(address => bool) public supportedFactories;

    /// @dev Reverts the transaction if the caller is a supported factory
    modifier onlyFactory() {
        require(supportedFactories[msg.sender], "OFH: FORBIDDEN");
        _;
    }

    /// @notice Add a supported factory
    /// @param _factory The address of the new factory
    function addFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "OFH: INVALID_ADDRESS");
        supportedFactories[_factory] = true;
        emit FactoryAdded(_factory);
    }

    /// @notice Remove a supported factory
    /// @param _factory The address of the factory to remove
    function removeFactory(address _factory) external onlyOwner {
        require(supportedFactories[_factory], "OFH: NOT_SUPPORTED");
        supportedFactories[_factory] = false;
        emit FactoryRemoved(_factory);
    }
}