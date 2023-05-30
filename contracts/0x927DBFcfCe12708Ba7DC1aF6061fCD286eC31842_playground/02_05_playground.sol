// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: playground
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    playground    //
//                  //
//                  //
//////////////////////


contract playground is ERC721Creator {
    constructor() ERC721Creator("playground", "playground") {}
}