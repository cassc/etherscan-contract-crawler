// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICollectionSupply {
    function maxSupply() external view returns (uint256);

    function setSupply(uint256 _maxSupply) external;

    function increaseSupply(uint256 amount) external;

    function decreaseSupply(uint256 amount) external;
}

interface IMintByUri {
    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) external;
}

interface ICollection is ICollectionSupply, IMintByUri {}