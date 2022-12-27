// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jpeg da Vinci 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    Some of Jpeg da Vinci’s favourite work curated for those with fine taste.    //
//                                                                                 //
//                                                                                 //
//    Enjoy these jpegs with pleasure                                              //
//                                                                                 //
//                                                                                 //
//    Jpeg da Vinci 22                                                             //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract JDV1 is ERC721Creator {
    constructor() ERC721Creator("Jpeg da Vinci 1/1", "JDV1") {}
}