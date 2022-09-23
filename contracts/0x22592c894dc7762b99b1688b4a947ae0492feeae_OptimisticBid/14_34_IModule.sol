// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions() external view returns (Permission[] memory permissions);
}