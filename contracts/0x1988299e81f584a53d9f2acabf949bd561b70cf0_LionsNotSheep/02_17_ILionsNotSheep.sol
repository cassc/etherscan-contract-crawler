// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILionsNotSheep {
    function burn(uint256 tokenId) external;

    function giftMint(address[] memory _addrs, uint256[] memory _tokenAmounts)
        external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}