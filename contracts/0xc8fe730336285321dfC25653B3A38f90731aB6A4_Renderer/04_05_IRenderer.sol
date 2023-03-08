// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRenderer {
    function tokenURI(
        uint256 amuletId,
        uint256 supply,
        string calldata title,
        string calldata amulet
    ) external view returns (string memory);
}