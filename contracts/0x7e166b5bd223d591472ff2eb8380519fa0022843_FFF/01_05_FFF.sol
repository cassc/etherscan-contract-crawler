// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FlippedVerse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    The FlippedVerse Open Edition.    //
//                                      //
//                                      //
//////////////////////////////////////////


contract FFF is ERC1155Creator {
    constructor() ERC1155Creator("FlippedVerse", "FFF") {}
}