// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CSM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    Multidisciplinary mixed-media artist.                                                         //
//                                                                                                  //
//    Exploring the subconscious through intuitive abstract narratives.                             //
//                                                                                                  //
//    Central St.Martins School of Art & Design, London. House of Abstract Exhibition Sept 2022.    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract CSM is ERC721Creator {
    constructor() ERC721Creator("CSM", "CSM") {}
}