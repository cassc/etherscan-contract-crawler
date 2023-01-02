// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLITCHKO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    GLITCHKO    //
//                //
//                //
////////////////////


contract GLTCHK is ERC721Creator {
    constructor() ERC721Creator("GLITCHKO", "GLTCHK") {}
}