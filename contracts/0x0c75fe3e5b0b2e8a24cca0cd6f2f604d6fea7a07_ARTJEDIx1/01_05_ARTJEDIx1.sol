// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTJEDIx1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ARTJEDI1    //
//                //
//                //
////////////////////


contract ARTJEDIx1 is ERC721Creator {
    constructor() ERC721Creator("ARTJEDIx1", "ARTJEDIx1") {}
}