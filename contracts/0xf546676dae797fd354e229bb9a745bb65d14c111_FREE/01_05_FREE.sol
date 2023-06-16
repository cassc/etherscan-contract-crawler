// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Four Freedoms by For Freedoms
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    FOUR FREEDOMS BY FOR FREEDOMS    //
//    IMAGES © FOR FREEDOMS            //
//    ALL RIGHTS RESERVED              //
//                                     //
//                                     //
/////////////////////////////////////////


contract FREE is ERC721Creator {
    constructor() ERC721Creator("Four Freedoms by For Freedoms", "FREE") {}
}