// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../token/LockableRevealERC721EnumerableToken.sol";
contract token is LockableRevealERC721EnumerableToken {

    constructor()
    LockableRevealERC721EnumerableToken(
        46,                           // _projectID
        966,                         // _maxSupply
        "NFTeria",                     // _name
        "NFTERIA",                    // _symbol
        "https://ether-cards.mypinata.cloud/ipfs/QmSRZkDuoK8ZD4HCZ1G3JNR4YgrBoFJFVCig6gBYg2Scrn",  // _tokenPreRevealURI
        "",                             // _tokenRevealURI
        false,                        // _transferLocked
        0,                            // _reservedSupply
        0                             // _giveawaySupply
    ) 
    {
    }

}