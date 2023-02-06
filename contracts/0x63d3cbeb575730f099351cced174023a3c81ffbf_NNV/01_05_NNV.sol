// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not Not Vested
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    +-+-+-+ +-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+-+-+    //
//    |n|o|t| |n|o|t| |a|n| |i|n|v|e|s|t|m|e|n|t|    //
//    +-+-+-+ +-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+-+-+    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract NNV is ERC721Creator {
    constructor() ERC721Creator("Not Not Vested", "NNV") {}
}