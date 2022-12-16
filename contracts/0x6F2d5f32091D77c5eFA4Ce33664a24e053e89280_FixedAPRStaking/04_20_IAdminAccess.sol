// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAdminAccess {
    function hasAdminRole(address) external view returns (bool);
    function addToAdminRole(address) external;
    function removeFromAdminRole(address) external;
    function getOwner() external view returns (address);
}