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

contract OldFashioned is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "OldFashioned",
            "OFC",
            "ipfs://QmesZZvTmakoYuE5FvA6M5ihtqmtRMQWfSwAnDnyGWnzja"
        )
    {}
}