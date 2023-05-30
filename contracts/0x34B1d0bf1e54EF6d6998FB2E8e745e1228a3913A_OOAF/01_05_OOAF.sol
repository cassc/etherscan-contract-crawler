// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Original Artwork by Andrew Foord
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    |————-||||____    //
//    \                 //
//    /                 //
//    |————-            //
//    |                 //
//    |                 //
//    |                 //
//    |                 //
//                      //
//                      //
//                      //
//////////////////////////


contract OOAF is ERC721Creator {
    constructor() ERC721Creator("Original Artwork by Andrew Foord", "OOAF") {}
}