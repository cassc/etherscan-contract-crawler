// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tweets
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Not a rug.    //
//                  //
//                  //
//////////////////////


contract TWEET is ERC721Creator {
    constructor() ERC721Creator("Tweets", "TWEET") {}
}