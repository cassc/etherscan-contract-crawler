// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashNFT {
    function mint(address _recipientAddress) external returns (uint256);

    function burn(uint256 _tokenId) external returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}