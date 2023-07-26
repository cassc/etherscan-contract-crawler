// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Superhero
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Angela Nikolau    //
//                      //
//                      //
//////////////////////////


contract WOW is ERC721Creator {
    constructor() ERC721Creator("Superhero", "WOW") {}
}