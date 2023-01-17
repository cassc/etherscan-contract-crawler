// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FXCKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    Fxcks inspired by Jack Butcher and Checks - VV.    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract FXCKS is ERC721Creator {
    constructor() ERC721Creator("FXCKS", "FXCKS") {}
}