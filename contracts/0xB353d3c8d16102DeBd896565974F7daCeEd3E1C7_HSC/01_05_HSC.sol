// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Faces of Water
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Howard Sheffield Collection     //
//                                    //
//                                    //
////////////////////////////////////////


contract HSC is ERC721Creator {
    constructor() ERC721Creator("Faces of Water", "HSC") {}
}