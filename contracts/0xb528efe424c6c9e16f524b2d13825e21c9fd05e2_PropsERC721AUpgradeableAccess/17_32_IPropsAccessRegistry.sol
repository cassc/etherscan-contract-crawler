// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IPropsAccessRegistry {
    /// @dev Adds role access entry in access registry.
    function add(address _account, address _deployment) external;

    /// @dev Reduces/Removes role access entry in access registry.
    function remove(address _account, address _deployment) external;
}