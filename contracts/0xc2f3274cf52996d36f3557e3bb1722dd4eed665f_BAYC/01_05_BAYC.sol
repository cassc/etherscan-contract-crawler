// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Funny Times
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    HZ ON TOP.    //
//                  //
//                  //
//////////////////////


contract BAYC is ERC721Creator {
    constructor() ERC721Creator("Bored Funny Times", "BAYC") {}
}