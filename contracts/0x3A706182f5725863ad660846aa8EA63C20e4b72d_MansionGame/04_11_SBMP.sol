// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SBMP {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external virtual payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external virtual payable;
}