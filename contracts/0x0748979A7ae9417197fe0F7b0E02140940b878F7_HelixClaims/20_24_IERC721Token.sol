// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC721Token {
    function ownerOf(uint256 _tokenId) external view returns (address);
}