// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vignettes in Verse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ## Vignettes in Verse               ##    //
//    ## A Collection by Glerren Bangalan ##    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract VgVrs is ERC721Creator {
    constructor() ERC721Creator("Vignettes in Verse", "VgVrs") {}
}