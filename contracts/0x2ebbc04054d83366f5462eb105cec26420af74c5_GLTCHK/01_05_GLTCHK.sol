// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLITCHKO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    GLITCHKO    //
//                //
//                //
////////////////////


contract GLTCHK is ERC1155Creator {
    constructor() ERC1155Creator("GLITCHKO", "GLTCHK") {}
}