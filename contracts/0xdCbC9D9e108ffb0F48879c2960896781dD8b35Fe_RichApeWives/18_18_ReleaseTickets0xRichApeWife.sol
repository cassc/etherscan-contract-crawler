// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ReleaseTickets0xRichApeWife {
    function totalSupply() external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
}