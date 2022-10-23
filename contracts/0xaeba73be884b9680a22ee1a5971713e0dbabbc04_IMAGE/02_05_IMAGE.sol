// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Imaginary Spaces
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Imaginary Spaces by indie.    //
//                                  //
//                                  //
//////////////////////////////////////


contract IMAGE is ERC721Creator {
    constructor() ERC721Creator("Imaginary Spaces", "IMAGE") {}
}