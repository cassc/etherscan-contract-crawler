// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnerChanger {
    function updateOwner(address currentOwner, address newOwner) external;
    function dropOwner(address currentOwner) external;
}