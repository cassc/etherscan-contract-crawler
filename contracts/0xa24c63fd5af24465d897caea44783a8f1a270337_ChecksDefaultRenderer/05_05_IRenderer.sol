// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPaintingRenderer {
    function render(uint256 tokenId, uint8[80] memory drawing)
        external
        view
        returns (string memory);
}