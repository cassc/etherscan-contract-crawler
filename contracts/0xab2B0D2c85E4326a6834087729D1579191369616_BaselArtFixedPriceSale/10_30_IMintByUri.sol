// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMintByUri {
    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) external;
}