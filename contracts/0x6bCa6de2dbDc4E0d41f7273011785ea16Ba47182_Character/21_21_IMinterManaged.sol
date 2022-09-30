// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMinterManaged {

    function setManager(address) external;

    function addMinter(address) external;

    function revokeMinter(address) external;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}