// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: v-day
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    henlo doon    //
//                  //
//                  //
//////////////////////


contract VDAY is ERC721Creator {
    constructor() ERC721Creator("v-day", "VDAY") {}
}