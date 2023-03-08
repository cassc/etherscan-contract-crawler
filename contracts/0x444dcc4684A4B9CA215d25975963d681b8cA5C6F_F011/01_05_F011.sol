// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: F011
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    F011--------------    //
//    by @felixlepeintre    //
//                          //
//                          //
//////////////////////////////


contract F011 is ERC721Creator {
    constructor() ERC721Creator("F011", "F011") {}
}