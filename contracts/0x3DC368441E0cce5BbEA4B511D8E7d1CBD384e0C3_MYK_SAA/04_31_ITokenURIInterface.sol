// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ITokenURIInterface {
    function createTokenURI(uint256 _tokenId) external  view returns (string memory);
}