// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../token/LockableRevealERC721EnumerableToken.sol";
contract token is LockableRevealERC721EnumerableToken {

    constructor()
    LockableRevealERC721EnumerableToken(
        84,                           // _projectID
        3500,                         // _maxSupply
        "Betwixt Braves",              // _name
        "BRAVES",                    // _symbol
        "https://camelcoding.mypinata.cloud/ipfs/QmU5aW6M18M4jBwnoaR6cbuRoLkv2qs6r9pLMdssVD8J9P",  // _tokenPreRevealURI
        "https://braves-metadata-server.herokuapp.com/api/metadata/",  // _tokenRevealURI
        false,                        // _transferLocked
        0,                            // _reservedSupply
        0                             // _giveawaySupply
    ) 
    {
    }

}