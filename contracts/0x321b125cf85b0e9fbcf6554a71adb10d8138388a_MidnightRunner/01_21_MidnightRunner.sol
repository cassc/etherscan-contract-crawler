// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: Midnight Runner
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./GeneticChainMetadata.sol";

//------------------------------------------------------------------------------
// Loomways
//------------------------------------------------------------------------------

/**
 * @title Midnight Runner
 * GeneticChain - Project #7 - Midnight Runner
 */
contract MidnightRunner is GeneticChainMetadata
{

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address[3] memory cards,
        string memory tokenIpfsHash,
        string memory baseUri,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChainMetadata(
          cards,
          tokenIpfsHash,
          baseUri,
          seed,
          proxyRegistryAddress)
    {
    }

}