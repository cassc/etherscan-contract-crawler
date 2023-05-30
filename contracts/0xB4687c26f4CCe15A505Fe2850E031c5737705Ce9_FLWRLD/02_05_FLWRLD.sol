// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flat world
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    A volumetric world in a flat style    //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract FLWRLD is ERC721Creator {
    constructor() ERC721Creator("Flat world", "FLWRLD") {}
}