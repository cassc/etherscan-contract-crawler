// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIFT: STATIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    SIFT STATIC THROUGH THE EYES OF THE MACHINE    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SIFT is ERC721Creator {
    constructor() ERC721Creator("SIFT: STATIC", "SIFT") {}
}