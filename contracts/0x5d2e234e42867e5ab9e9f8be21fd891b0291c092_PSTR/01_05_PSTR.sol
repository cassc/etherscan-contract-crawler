// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Certified WMPs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ___  ____ ____ ____ ___ ____ ____ . ____     //
//    |__] |___ |__| [__   |  |___ |__/ ' [__      //
//    |    |___ |  | ___]  |  |___ |  \   ___]     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract PSTR is ERC721Creator {
    constructor() ERC721Creator("Certified WMPs", "PSTR") {}
}