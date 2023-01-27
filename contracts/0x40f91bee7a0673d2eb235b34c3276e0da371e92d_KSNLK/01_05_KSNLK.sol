// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lightning Knights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                   __                     //
//    |/._ o _ |__|_ _ \    /|_  _  (_  _.   |\ | _.|_      //
//    |\| ||(_|| ||__>  \/\/ | |(_) __)(_|\/ | \|(_|| |     //
//           _|                           /                 //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract KSNLK is ERC721Creator {
    constructor() ERC721Creator("Lightning Knights", "KSNLK") {}
}