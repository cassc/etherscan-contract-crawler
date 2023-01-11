// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimalink
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Minimalink by Akashi30                     //
//    NO AFFILIATION with any other projects.    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MLK is ERC1155Creator {
    constructor() ERC1155Creator("Minimalink", "MLK") {}
}