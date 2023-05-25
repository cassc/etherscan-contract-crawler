// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../token/LockableRevealERC721EnumerableToken.sol";

contract token is LockableRevealERC721EnumerableToken {

    constructor()
    LockableRevealERC721EnumerableToken(
        1,                            // _projectID
        9000,                         // _maxSupply
        "Girls, Robots, Dragons",     // _name
        "GRD",                        // _symbol
        "https://ether-cards.mypinata.cloud/ipfs/QmSFpNVrszpEHpHRJVJnCzKcyr5fsK48KZ9kC5Qz3bjNMx",  // _tokenPreRevealURI
        "https://metadata.grd.fan/",  // _tokenRevealURI
        false,                        // _transferLocked
        300,                          // _reservedSupply
        300,                          // _giveawaySupply
        "https://metadata.grd.fan/api/contract" // contractURI
    ) 
    {

    }


}