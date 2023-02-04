// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MyNewWord
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    MM    MM  NN   NN  WW       WW    //
//    MMM  MMM  NNN  NN  WWW  W   WW    //
//    MM MM MM  NN N NN  WW WW WW WW    //
//    MM    MM  NN  NNN  WW       WW    //
//    MM    MM  NN   NN  WW       WW    //
//                                      //
//                                      //
//////////////////////////////////////////


contract MNW is ERC721Creator {
    constructor() ERC721Creator("MyNewWord", "MNW") {}
}