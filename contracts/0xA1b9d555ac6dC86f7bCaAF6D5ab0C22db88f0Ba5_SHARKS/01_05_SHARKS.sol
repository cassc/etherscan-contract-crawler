// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sharks in the Water
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(     //
//    `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SHARKS is ERC721Creator {
    constructor() ERC721Creator("Sharks in the Water", "SHARKS") {}
}