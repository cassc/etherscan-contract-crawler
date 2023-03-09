/**
    ┌─────────────────────────────────────────────────────────────────┐
    |             --- DEVELOPED BY JackOnChain (JOC) ---              |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    └─────────────────────────────────────────────────────────────────┘                                               
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./JOCSpeakEasyERC721.sol";

contract EMPCocktail is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "EMPCocktail",
            "EMPC",
            "ipfs://QmU1GytDf8ECS648Y9DBQSEvLAae5y8rWVWSKxqjheAbET"
        )
    {}
}