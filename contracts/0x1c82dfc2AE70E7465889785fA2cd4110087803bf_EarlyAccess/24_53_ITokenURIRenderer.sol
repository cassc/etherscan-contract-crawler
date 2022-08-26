// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenURIRenderer {
    function render(address nftContract, uint256 tokenId) external view returns (string memory output);
}