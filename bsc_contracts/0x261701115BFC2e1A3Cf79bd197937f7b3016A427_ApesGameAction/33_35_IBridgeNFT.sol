//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeNFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function checkBridge(uint256 tokenID) external view returns(bool pass);
    function bridgeMint(address to, uint256 tokenID) external;
    function bridgeBurn(uint256 tokenID) external;
}