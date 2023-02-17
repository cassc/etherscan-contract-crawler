// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clowns by pixeljunkie
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     +-+-+-+-+-+-+              //
//     |c|l|o|w|n|s|              //
//     +-+-+-+-+-+-+              //
//     |b|y|                      //
//     +-+-+-+-+-+-+-+-+-+-+-+    //
//     |p|i|x|e|l|j|u|n|k|i|e|    //
//     +-+-+-+-+-+-+-+-+-+-+-+    //
//                                //
//                                //
////////////////////////////////////


contract CLOWN is ERC721Creator {
    constructor() ERC721Creator("Clowns by pixeljunkie", "CLOWN") {}
}