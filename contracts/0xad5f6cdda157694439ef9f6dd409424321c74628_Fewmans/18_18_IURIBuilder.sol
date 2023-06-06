//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IURIBuilder {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}