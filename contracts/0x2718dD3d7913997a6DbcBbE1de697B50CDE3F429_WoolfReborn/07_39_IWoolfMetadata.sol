// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.17;

interface IWoolfMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}