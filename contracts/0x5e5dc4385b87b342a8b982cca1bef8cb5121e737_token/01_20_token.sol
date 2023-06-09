// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../token/LockableRevealERC721EnumerableToken.sol";
contract token is LockableRevealERC721EnumerableToken {

    constructor()
    LockableRevealERC721EnumerableToken(
        28,                           // _projectID
        1777,                         // _maxSupply
        "Betwixt Elder",              // _name
        "BETWIXT",                    // _symbol
        "https://ether-cards.mypinata.cloud/ipfs/QmfHw35SM8k6HCjeCaXuYfEgtChnCjRjVDq7fLsG6s2eJ2",  // _tokenPreRevealURI
        "https://betwixt-metadata-server.herokuapp.com/api/metadata/",  // _tokenRevealURI
        false,                        // _transferLocked
        0,                            // _reservedSupply
        0                             // _giveawaySupply
    ) 
    {
    }

}