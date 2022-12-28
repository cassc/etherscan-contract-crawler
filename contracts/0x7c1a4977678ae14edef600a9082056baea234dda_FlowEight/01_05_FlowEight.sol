// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flow Eight
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Flow Eight    //
//                  //
//                  //
//////////////////////


contract FlowEight is ERC721Creator {
    constructor() ERC721Creator("Flow Eight", "FlowEight") {}
}