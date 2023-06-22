// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtMembership {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}