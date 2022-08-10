// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: theblackartist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    theblackartist    //
//                      //
//                      //
//////////////////////////


contract TBA is ERC721Creator {
    constructor() ERC721Creator("theblackartist", "TBA") {}
}