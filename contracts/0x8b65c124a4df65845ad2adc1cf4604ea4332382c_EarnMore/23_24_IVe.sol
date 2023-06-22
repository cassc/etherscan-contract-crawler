// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVe {
    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOfNFT(uint256 tokenId) external view returns (uint256);
}