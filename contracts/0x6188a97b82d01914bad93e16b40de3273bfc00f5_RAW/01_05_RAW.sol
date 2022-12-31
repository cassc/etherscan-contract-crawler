// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Random Access Works
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    a scene without light        //
//    an artist without fortune    //
//    but it is okay.              //
//                                 //
//                                 //
/////////////////////////////////////


contract RAW is ERC721Creator {
    constructor() ERC721Creator("Random Access Works", "RAW") {}
}