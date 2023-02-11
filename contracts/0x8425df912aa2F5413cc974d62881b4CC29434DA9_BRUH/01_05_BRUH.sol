// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VibeChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    DO YOU PASS THE VIBECHECK?    //
//                                  //
//                                  //
//////////////////////////////////////


contract BRUH is ERC721Creator {
    constructor() ERC721Creator("VibeChecks", "BRUH") {}
}