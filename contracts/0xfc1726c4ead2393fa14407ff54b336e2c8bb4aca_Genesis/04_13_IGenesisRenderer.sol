//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGenesisRenderer {
    function tokenURI(
        uint256 tokenId,
        uint256 blockNumber,
        uint256 mergeBlock
    ) external view returns (string memory);
}