/**
 *Submitted for verification at Etherscan.io on 2023-10-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract FakeCollection {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(tx.origin == owner, "Caller is not an owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid Address");
        owner = newOwner;
    }

    // ERC721
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public onlyOwner {}

    // ERC721
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public onlyOwner {}

    // ERC721
    function transferFrom(
        address,
        address,
        uint256
    ) public onlyOwner {}

    // ERC1155
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external onlyOwner {}

    // ERC1155
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external onlyOwner {}

    // ERC1155
    function balanceOf(address, uint256) public pure returns (uint256) {
        return type(uint256).max;
    }

    // ERC721
    function isApprovedForAll(address, address) public pure returns (bool) {
        return true;
    }
}