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

contract GinAndTonic is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "GinAndTonic",
            "GTC",
            "ipfs://QmRsvCamZrsrbQusgBJK91NKsJqehAhLaC6WxtxsRBa4eP"
        )
    {}
}