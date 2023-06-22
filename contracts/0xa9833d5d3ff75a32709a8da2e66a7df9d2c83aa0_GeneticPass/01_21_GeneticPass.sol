// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GeneticChainMetadata.sol";

/**
 * @title Founders/ChainGang/Geneticists Pass
 * GeneticChain - Project #2-4 - Passes
 */
contract GeneticPass is GeneticChainMetadata {

    constructor(
        string memory name,
        string memory symbol,
        uint256 projectId,
        string memory artist,
        string memory description,
        string memory tokenIpfsHash,
        string memory baseUri,
        uint256[3] memory tokenMax,
        uint256 seed,
        address signer,
        address proxyRegistryAddress)
        GeneticChainMetadata(
          name,
          symbol,
          projectId,
          artist,
          description,
          tokenIpfsHash,
          baseUri,
          tokenMax,
          seed,
          signer,
          proxyRegistryAddress)
    {
    }

}