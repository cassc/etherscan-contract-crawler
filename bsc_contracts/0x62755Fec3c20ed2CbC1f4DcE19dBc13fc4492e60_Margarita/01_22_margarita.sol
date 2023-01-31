/**
    ┌─────────────────────────────────────────────────────────────────┐
    |             --- DEVELOPED BY JackOnChain (JOC) ---              |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    |                      Discord: JackT#8310                        |
    └─────────────────────────────────────────────────────────────────┘                                               
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./JOCSpeakEasyERC721.sol";

contract Margarita is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "Margarita",
            "MGC",
            "ipfs://QmTvXyQtuJF4UFRWWPhRkKUk9B3ZqVAd1usAwnBsAPM5Qz"
        )
    {}
}