// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charlie Ma 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    charlie ma    //
//                  //
//                  //
//////////////////////


contract CHMA is ERC721Creator {
    constructor() ERC721Creator("Charlie Ma 1/1s", "CHMA") {}
}