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

contract SWCCocktail is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "SWCCocktail",
            "SWCC",
            "ipfs://QmNLrMebxB5YGbRTF7Rvv56gdm78WYsU6gfmMQUo2wCvMK"
        )
    {}
}