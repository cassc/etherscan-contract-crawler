// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OGREglyphs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    OGRE    //
//            //
//            //
//            //
////////////////


contract OGREglyphs is ERC721Creator {
    constructor() ERC721Creator("OGREglyphs", "OGREglyphs") {}
}