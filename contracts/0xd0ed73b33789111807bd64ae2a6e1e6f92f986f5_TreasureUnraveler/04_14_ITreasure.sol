// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ITreasure is IERC721 {
    function ownerOf(uint256 tokenId)
        external
        view
        override
        returns (address owner);

    function getAsset1(uint256 tokenId) external view returns (string memory);

    function getAsset2(uint256 tokenId) external view returns (string memory);

    function getAsset3(uint256 tokenId) external view returns (string memory);

    function getAsset4(uint256 tokenId) external view returns (string memory);

    function getAsset5(uint256 tokenId) external view returns (string memory);

    function getAsset6(uint256 tokenId) external view returns (string memory);

    function getAsset7(uint256 tokenId) external view returns (string memory);

    function getAsset8(uint256 tokenId) external view returns (string memory);
}