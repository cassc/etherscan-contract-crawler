// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IQuantumBlackList {
    function initialize(address admin) external;

    function addToBlackList(address[] calldata users) external;

    function removeFromBlackList(address user) external;

    function isBlackListed(address user) external view returns (bool);
}