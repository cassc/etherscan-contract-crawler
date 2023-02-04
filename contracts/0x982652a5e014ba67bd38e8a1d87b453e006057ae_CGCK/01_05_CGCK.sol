// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CGChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    8""""8 8""""8    8""""8 8   8 8"""" 8""""8 8   8  8""""8     //
//    8    " 8    "    8    " 8   8 8     8    " 8   8  8          //
//    8e     8e        8e     8eee8 8eeee 8e     8eee8e 8eeeee     //
//    88     88  ee    88     88  8 88    88     88   8     88     //
//    88   e 88   8    88   e 88  8 88    88   e 88   8 e   88     //
//    88eee8 88eee8    88eee8 88  8 88eee 88eee8 88   8 8eee88     //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract CGCK is ERC721Creator {
    constructor() ERC721Creator("CGChecks", "CGCK") {}
}