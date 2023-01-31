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

contract BloodyMary is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "BloodyMary",
            "BMC",
            "ipfs://QmPWEKKWoxoXmKNtgcVJc6pA2yPivxdHRQnvhwB4Kgk4Fj"
        )
    {}
}