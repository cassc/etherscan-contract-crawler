// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xRothko
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    using deep learning to generate generative unseen art 0xRothkos    //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract OxRot is ERC721Creator {
    constructor() ERC721Creator("0xRothko", "OxRot") {}
}