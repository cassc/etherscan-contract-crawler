// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Klim Nova Arts & Design
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Klim Nova Arts & Design.         //
//                                     //
//    https://twitter.com/Novaklim1    //
//                                     //
//                                     //
/////////////////////////////////////////


contract KNAD is ERC721Creator {
    constructor() ERC721Creator("Klim Nova Arts & Design", "KNAD") {}
}