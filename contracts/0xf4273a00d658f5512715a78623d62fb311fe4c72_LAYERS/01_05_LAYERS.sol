// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LASAGNA EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    LASAGNA PROJECTS EDITIONS    //
//                                 //
//                                 //
/////////////////////////////////////


contract LAYERS is ERC1155Creator {
    constructor() ERC1155Creator("LASAGNA EDITIONS", "LAYERS") {}
}