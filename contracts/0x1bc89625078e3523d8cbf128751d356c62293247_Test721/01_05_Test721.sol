// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 721 Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Ascii here    //
//                  //
//                  //
//////////////////////


contract Test721 is ERC721Creator {
    constructor() ERC721Creator("721 Test", "Test721") {}
}