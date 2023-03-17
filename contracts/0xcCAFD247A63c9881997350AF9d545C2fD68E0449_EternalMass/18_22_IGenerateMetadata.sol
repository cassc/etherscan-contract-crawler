// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

interface IGenerateMetadata {

    /**
     * @notice Read and generate the NFT metadata on-chain
     * @param tokenId The NFT token id to get the token metadata
     * @return metadata encoded in Base64
     */
    function tokenMetadata(uint256 tokenId) external view returns (string memory);

}