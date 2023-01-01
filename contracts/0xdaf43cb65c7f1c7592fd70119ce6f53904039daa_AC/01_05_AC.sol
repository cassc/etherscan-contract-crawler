// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: arami commission
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    commission request    //
//                          //
//                          //
//////////////////////////////


contract AC is ERC721Creator {
    constructor() ERC721Creator("arami commission", "AC") {}
}