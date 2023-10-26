// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: h3xum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract hexum is ERC721Creator {
    constructor() ERC721Creator("h3xum", "hexum") {}
}