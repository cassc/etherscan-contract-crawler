/**
    ┌─────────────────────────────────────────────────────────────────┐
    |                  --- DEVELOPED BY JackT ---                     |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    |                      Discord: JackT#8310                        |
    └─────────────────────────────────────────────────────────────────┘                                               
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./JOCSpeakEasyERC721.sol";

contract PinaColada is JOCSpeakEasyERC721 {

    constructor()
        JOCSpeakEasyERC721(
            "PinaColada",
            "PCC",
            "ipfs://QmNyanFNkgkqYRjmPYCRTKRCE8KSxMSNpSuJ7WASEjgSTu"
        )
    {}
}