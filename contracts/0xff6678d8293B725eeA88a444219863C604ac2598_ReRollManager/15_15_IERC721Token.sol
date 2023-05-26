// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Token {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);
}