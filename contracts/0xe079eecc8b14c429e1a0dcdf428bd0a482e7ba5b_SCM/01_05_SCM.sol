// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sky City Music
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Sky City Music    //
//                      //
//                      //
//////////////////////////


contract SCM is ERC721Creator {
    constructor() ERC721Creator("Sky City Music", "SCM") {}
}