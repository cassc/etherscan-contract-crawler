// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PassageAccess is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice returns true if the given _address has UPGRADER_ROLE
    /// @param _address Address to check for UPGRADER_ROLE
    /// @return bool whether _address has UPGRADER_ROLE
    function hasUpgraderRole(address _address) public view virtual returns (bool) {
        return hasRole(UPGRADER_ROLE, _address);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[100] private __gap;
}