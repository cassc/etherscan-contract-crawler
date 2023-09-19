// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "base-nft-contract/contracts/BaseNFTCollection.sol";

/**
 * @title Walks of Life Light NFT contract
 *  __      __       ____     
 * /  \    /  \____ |    |    
 * \   \/\/   /  _ \|    |    
 *  \        (  <_> )    |___ 
 *   \__/\  / \____/|_______ \
 *        \/                \/
 */
contract WolLight is BaseNFTCollection {
    constructor(uint price_, string memory baseUrl_, uint maxTokens_, uint firstMintNumber, uint96 feeNumerator) BaseNFTCollection(price_, baseUrl_,maxTokens_, firstMintNumber, feeNumerator) ERC721("Walks of Life", "WoL") {
        
    }
}