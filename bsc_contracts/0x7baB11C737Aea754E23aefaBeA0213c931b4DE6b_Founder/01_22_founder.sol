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

import "./JOCSpeakEasyLockedERC721.sol";

contract Founder is JOCSpeakEasyLockedERC721 {

    constructor()
        JOCSpeakEasyLockedERC721(
            "Founder",
            "FON",
            "ipfs://QmPertuGKT6zF8vdksiB14U1uRZr9GFz8mML6hCpjPMPxu"
        )
    {}
}