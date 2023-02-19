// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WHO STOLE MY ART ?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    Who stole my art ?                                           //
//    Someone came into that Web3 gallery, jealousy ? Passion ?    //
//    We'll see in the future...                                   //
//    It's a tribute to Grant Yun and 0xdgb.                       //
//                                                                 //
//    Camera cow.                                                  //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract OWL is ERC721Creator {
    constructor() ERC721Creator("WHO STOLE MY ART ?", "OWL") {}
}