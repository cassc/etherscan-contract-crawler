// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for NodeRole which wraps the default artist role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface INodeRole {
    function isNode(address account) external view returns (bool);
}