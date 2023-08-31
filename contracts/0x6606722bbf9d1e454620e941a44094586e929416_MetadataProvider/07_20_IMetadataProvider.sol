// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMetadataProvider {
    function tokenURI(uint256 tokenId, address replicanContract, bool validity, bytes memory data)
        external
        view
        returns (string memory);
}