// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract OGacc {

    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function _burn(uint256 tokenId) external virtual;

    function transferFrom(address from, address to, uint256 tokenId) public virtual;

    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;

    function setApprovalForAll(address operator, bool approved) public virtual;

    function approve(address to, uint256 tokenId) public virtual;

}