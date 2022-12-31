// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You Are One of a Kind
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    //////////////////////////    //
//    //                      //    //
//    //                      //    //
//    //    @thedesignerof    //    //
//    //                      //    //
//    //                      //    //
//    //////////////////////////    //
//                                  //
//                                  //
//////////////////////////////////////


contract MOS is ERC721Creator {
    constructor() ERC721Creator("You Are One of a Kind", "MOS") {}
}