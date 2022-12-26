// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Catalog Of Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Catalog Of Editions by Frank Achon    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CAED is ERC721Creator {
    constructor() ERC721Creator("Catalog Of Editions", "CAED") {}
}