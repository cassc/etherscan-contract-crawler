// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IOnChainKevinRenderer {
    function _tokenIdToHash(uint256 tokenId) external view returns (string memory);
    function hashToSVG(string memory _hash) external view returns (string memory);
    function hashToMetadata(string memory _hash) external view returns (string memory);
}