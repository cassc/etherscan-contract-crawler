// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lilunivrz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    hEllo wOrld tHis iS mY wEb3 dEbut.                                                       //
//                                                                                             //
//    I'm a 10 year old artist and had fun making this piece.                                  //
//    This originally was gonna be scrapped but after my family saw this,                      //
//    they pushed me to get this minted.                                                       //
//    Can't say much about what's next as it'll be an evolution but would love the support     //
//    and hope you enjoy the first of many.                                                    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract lilunivrz is ERC721Creator {
    constructor() ERC721Creator("lilunivrz", "lilunivrz") {}
}