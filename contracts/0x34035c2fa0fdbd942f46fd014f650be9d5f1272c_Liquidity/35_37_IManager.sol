// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Interface to add allowed operator in addition to owner
abstract contract IManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private managers;

    /// @notice Requires the sender to be a manager
    modifier onlyManager() {
        require(managers.contains(msg.sender), "You do not have rights");
        _;
    }

    /// @dev Emitted when a manager is added
    event ManagerAdded(address);
    /// @dev Emitted when a manager is removed
    event ManagerRemoved(address);

    /// @notice Add a manager
    /// @param _manager The address of the manager to add
    function addManager(address _manager) external virtual;

    /// @notice Remove a manager
    /// @param _manager The address of the manager to remove
    function removeManager(address _manager) external virtual;

    /// @dev Add a manager internally
    /// @param _manager The address of the manager to add
    function _addManager(address _manager) internal {
        require(_manager != address(0), "Address should not be empty");
        require(!managers.contains(_manager), "Already added");
        managers.add(_manager);
        emit ManagerAdded(_manager);

    }

    /// @dev Remove a manager internally
    /// @param _manager The address of the manager to remove
    function _removeManager(address _manager) internal {
        require(managers.contains(_manager), "Not exist");
        managers.remove(_manager);
        emit ManagerRemoved(_manager);
    }

    /// @notice Get the list of managers
    /// @return An array of manager addresses
    function getManagers() external view returns (address[] memory) {
        return managers.values();
    }
}