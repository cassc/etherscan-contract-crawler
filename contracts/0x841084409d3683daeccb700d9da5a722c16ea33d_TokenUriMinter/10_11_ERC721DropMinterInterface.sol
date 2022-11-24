// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721DropMinterInterface {
    function adminMint(address recipient, uint256 quantity)
        external
        returns (uint256);

    function hasRole(bytes32, address) external returns (bool);

    function isAdmin(address) external returns (bool);
}