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

contract GoldMKC is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "GoldMKC",
            "GMKC",
            "ipfs://QmaP2okJAMfUUDaPi9Y72P4w5BrdSDj5R9z3F1EC3eEjRU"
        )
    {}
}