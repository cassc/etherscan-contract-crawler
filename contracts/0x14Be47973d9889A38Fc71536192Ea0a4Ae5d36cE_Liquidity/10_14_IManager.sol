// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Interface to add allowed operator in addition to owner
 */
abstract contract IManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private managers;

    modifier onlyManager() {
        require(managers.contains(msg.sender), "You do not have rights");
        _;
    }

    event ManagerAdded(address);
    event ManagerRemoved(address);

    function addManager(address _manager) external virtual;

    function removeManager(address _manager) external virtual;

    function _addManager(address _manager) internal {
        require(_manager != address(0), "Address should not be empty");
        require(!managers.contains(_manager), "Already added");
        managers.add(_manager);
        emit ManagerAdded(_manager);

    }

    function _removeManager(address _manager) internal {
        require(managers.contains(_manager), "Not exist");
        managers.remove(_manager);
        emit ManagerRemoved(_manager);
    }

    function getManagers() external view returns (address[] memory) {
        return managers.values();
    }
}