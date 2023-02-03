// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IJSONExtensionRegistry {
    function setJSONExtension(address target, string memory uri)
        external;

    function getJSONExtension(address target)
        external
        returns (string memory);

    error RequiresContractAdmin();

    event JSONExtensionUpdated(
        address indexed target,
        address indexed updater,
        string newValue
    );
}