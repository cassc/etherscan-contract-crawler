// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 7nov.bee
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    👧👧    //
//            //
//            //
////////////////


contract TWIN is ERC721Creator {
    constructor() ERC721Creator("7nov.bee", "TWIN") {}
}