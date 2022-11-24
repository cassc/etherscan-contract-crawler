// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenUriMetadataRenderer {
    function updateTokenURI(address, uint256, string memory) external;
    function updateContractURI(address, string memory) external;
}