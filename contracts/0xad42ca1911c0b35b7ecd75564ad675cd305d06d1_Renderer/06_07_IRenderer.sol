// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IRenderer {
    struct SpiroData {
        uint8 points;
        uint8 wheelSize1;
        uint8 wheelRate1;
        uint8 wheelSize2;
        uint8 wheelRate2;
        string colorName;
        string colorValue;
    }

    function renderSpiro(SpiroData memory spiroData) external pure returns (string memory);

    function tokenURI(uint256 tokenId, uint256 seed) external pure returns (string memory);
}