// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: She is the light that I come home for
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    '||                               //
//     ||    ...   .... ...   ....      //
//     ||  .|  '|.  '|.  |  .|...||     //
//     ||  ||   ||   '|.|   ||          //
//    .||.  '|..|'    '|     '|...'     //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract Universe is ERC721Creator {
    constructor() ERC721Creator("She is the light that I come home for", "Universe") {}
}