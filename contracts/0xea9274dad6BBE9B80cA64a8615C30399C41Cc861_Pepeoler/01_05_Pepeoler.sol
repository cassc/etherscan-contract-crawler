// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepeoler
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    aloroler x 🐸     //
//    feels good man    //
//                      //
//                      //
//////////////////////////


contract Pepeoler is ERC721Creator {
    constructor() ERC721Creator("Pepeoler", "Pepeoler") {}
}