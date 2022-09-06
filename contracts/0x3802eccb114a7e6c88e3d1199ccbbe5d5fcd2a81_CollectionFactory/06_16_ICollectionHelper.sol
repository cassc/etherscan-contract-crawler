// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICollectionHelper {
    function getType(address collection) external view returns (uint8);

    function deploy(
        address owner,
        string memory name,
        string memory symbol,
        bool is721
    ) external returns (address);
}