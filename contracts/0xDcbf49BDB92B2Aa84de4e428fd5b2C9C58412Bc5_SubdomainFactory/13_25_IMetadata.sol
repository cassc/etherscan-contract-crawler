//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns(string memory);
}