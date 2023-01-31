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

contract IrishCoffee is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "IrishCoffee",
            "ICC",
            "ipfs://QmXsCAs1Jcrg7cygLYJZpX91q5yp4aDRgL1PNvtPKUgUqM"
        )
    {}
}