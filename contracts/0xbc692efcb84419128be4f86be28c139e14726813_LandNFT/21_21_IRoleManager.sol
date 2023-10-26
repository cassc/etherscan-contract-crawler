// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

// interface for IRoleManager
interface IRoleManager is IAccessControlUpgradeable{
    function hasRole(bytes32 role, address account) external view returns (bool);
}