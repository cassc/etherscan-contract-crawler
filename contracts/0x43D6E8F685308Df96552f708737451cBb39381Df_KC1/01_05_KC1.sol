// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karel Chladek 1:1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//                              //
//    .%%..%%..%%%%....%%...    //
//    .%%.%%..%%..%%..%%%...    //
//    .%%%%...%%.......%%...    //
//    .%%.%%..%%..%%...%%...    //
//    .%%..%%..%%%%..%%%%%%.    //
//    ......................    //
//                              //
//                              //
//                              //
//////////////////////////////////


contract KC1 is ERC721Creator {
    constructor() ERC721Creator("Karel Chladek 1:1", "KC1") {}
}