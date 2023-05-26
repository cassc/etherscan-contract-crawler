// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMeritBurnableNFT {
    function burn(uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}