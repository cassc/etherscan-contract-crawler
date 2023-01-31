// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MystPass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    MYYYYYYYYYYYST    //
//                      //
//                      //
//////////////////////////


contract MYSTP is ERC721Creator {
    constructor() ERC721Creator("MystPass", "MYSTP") {}
}