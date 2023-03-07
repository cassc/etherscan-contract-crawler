// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shamzuka CampFire
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Shamzuka    //
//                //
//                //
////////////////////


contract SCF is ERC721Creator {
    constructor() ERC721Creator("Shamzuka CampFire", "SCF") {}
}