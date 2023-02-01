// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity 0.8.17;

interface IOnChainKevin {
    function tokenIdToHash(uint256 tokenId) external view returns (string memory);
    function hashToSVG(string memory _hash) external view returns (string memory);
    function hashToMetadata(string memory _hash) external view returns (string memory);
}