// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

interface ITwinCloud {

    function safeMint(address to, uint256 quantity) external;
    function safeTransferFrom(address from,address to,uint256 tokenId) external payable;
}