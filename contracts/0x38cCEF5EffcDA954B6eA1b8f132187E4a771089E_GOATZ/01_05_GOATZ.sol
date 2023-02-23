// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Goat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    Wanna become the GOAT?                                                     //
//    Get ready to cop the hottest Open Edition NFT GOAT out there!              //
//    It's a one-of-a-kind, limited edition collectible that's off the chain.    //
//    Plus, minters get access to the closed alpha Discord.                      //
//    Don't miss out, fam. 🔥🐐                                                  //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract GOATZ is ERC721Creator {
    constructor() ERC721Creator("Goat", "GOATZ") {}
}