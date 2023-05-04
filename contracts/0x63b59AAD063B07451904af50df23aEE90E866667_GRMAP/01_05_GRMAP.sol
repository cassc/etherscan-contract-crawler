// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRM Artist Portraits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                  //
//                                                                                                                                                  //
//    GRM Artist Portraits. Gallery owner since 1994 and always in search of the authentic work. No epigonism. Out of oneself towards the truth.    //
//                                                                                                                                                  //
//                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GRMAP is ERC721Creator {
    constructor() ERC721Creator("GRM Artist Portraits", "GRMAP") {}
}