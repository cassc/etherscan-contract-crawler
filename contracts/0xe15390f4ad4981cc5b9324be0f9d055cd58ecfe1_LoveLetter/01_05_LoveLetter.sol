// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A lonely night.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Lonely night.                              //
//                                               //
//    Music composed and arranged by owlcean.    //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract LoveLetter is ERC721Creator {
    constructor() ERC721Creator("A lonely night.", "LoveLetter") {}
}