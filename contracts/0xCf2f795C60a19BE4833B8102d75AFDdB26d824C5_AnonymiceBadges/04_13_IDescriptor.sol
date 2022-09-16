// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IDescriptor {
    function badgeImages(uint256 badgeId) external view returns (string memory);

    function boardImages(uint256 boardId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getSvg(uint256 id) external view returns (string memory);

    function buildSvg(
        uint256 boardId,
        uint256[] memory poaps,
        string memory boardName,
        bool isPreview
    ) external view returns (string memory);
}