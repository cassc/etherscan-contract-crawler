// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEEKAY 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    DeeKay 1/1                    //
//                                  //
//    twitter.com/deekaymotion      //
//    instagram.com/deekaymotion    //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract DK1 is ERC721Creator {
    constructor() ERC721Creator("DEEKAY 1/1", "DK1") {}
}