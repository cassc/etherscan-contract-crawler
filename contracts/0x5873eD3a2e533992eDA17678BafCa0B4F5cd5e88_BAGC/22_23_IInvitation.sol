// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface InvitationNft {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external returns (address owner);
}