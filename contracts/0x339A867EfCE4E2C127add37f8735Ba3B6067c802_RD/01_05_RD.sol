// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Run Day
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Style mark    //
//                  //
//                  //
//////////////////////


contract RD is ERC721Creator {
    constructor() ERC721Creator("Run Day", "RD") {}
}