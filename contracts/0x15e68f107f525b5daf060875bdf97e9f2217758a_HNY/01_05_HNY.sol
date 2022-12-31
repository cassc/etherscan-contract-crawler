// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy New Year!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    +-+-+-+-+-+    //
//    |C|H|U|B|I|    //
//    +-+-+-+-+-+    //
//                   //
//                   //
///////////////////////


contract HNY is ERC721Creator {
    constructor() ERC721Creator("Happy New Year!", "HNY") {}
}