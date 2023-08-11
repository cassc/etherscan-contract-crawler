// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IOriginNft {
    function ownerOf(uint256 tokenId) external view returns (address);
}