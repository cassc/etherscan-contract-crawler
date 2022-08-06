// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cold and desolate
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    Milwaukee is one of the few places in the United States where April can feel like November.    //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//    The spring sunrise did not bring any warmth to the land, and even made people feel bleak.      //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//    Milwaukee, for the most part, is just cold.                                                    //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//    But...                                                                                         //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract CAD is ERC721Creator {
    constructor() ERC721Creator("cold and desolate", "CAD") {}
}