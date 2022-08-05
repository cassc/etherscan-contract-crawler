// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MariliaHenriquesART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    My Painting, Drawing and Collage works    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MHART is ERC721Creator {
    constructor() ERC721Creator("MariliaHenriquesART", "MHART") {}
}