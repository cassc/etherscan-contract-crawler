// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fey Realm
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     +-+-+-+-+-+            //
//     |E|n|d|e|r|            //
//     +-+-+-+-+-+            //
//     |D|i|r|i|l|            //
//     +-+-+-+-+-+-+-+-+-+    //
//     |F|e|y| |R|e|a|l|m|    //
//     +-+-+-+ +-+-+-+-+-+    //
//    enderdiril.eth          //
//    in 2023                 //
//                            //
//                            //
////////////////////////////////


contract EDFR is ERC721Creator {
    constructor() ERC721Creator("Fey Realm", "EDFR") {}
}