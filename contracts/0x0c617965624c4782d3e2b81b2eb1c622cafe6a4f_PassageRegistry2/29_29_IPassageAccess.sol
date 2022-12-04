// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IPassageAccess is IAccessControlUpgradeable {
    function hasUpgraderRole(address _address) external view returns (bool);
}