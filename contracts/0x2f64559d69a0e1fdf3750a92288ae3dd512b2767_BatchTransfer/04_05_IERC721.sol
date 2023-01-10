// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./IERC165.sol";

abstract contract IERC721 is IERC165 {
    function balanceOf(address owner) public virtual view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public virtual view returns (address operator);
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool);
}

