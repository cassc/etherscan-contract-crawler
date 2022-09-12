// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wireframe City
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Wireframe City by indie.    //
//                                //
//                                //
////////////////////////////////////


contract WCITY is ERC721Creator {
    constructor() ERC721Creator("Wireframe City", "WCITY") {}
}