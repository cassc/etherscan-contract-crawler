// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for ModuleRole which wraps the default artist role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IModuleRole {
    function isModule(address account) external view returns (bool);
}