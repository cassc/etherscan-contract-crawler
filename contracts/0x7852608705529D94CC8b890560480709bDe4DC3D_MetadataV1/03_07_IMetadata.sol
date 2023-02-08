// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetadata {
    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);
}