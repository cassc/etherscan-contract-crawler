// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RenderJuice 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    RenderJuice • 2023    //
//                          //
//                          //
//////////////////////////////


contract RJ23 is ERC721Creator {
    constructor() ERC721Creator("RenderJuice 2023", "RJ23") {}
}