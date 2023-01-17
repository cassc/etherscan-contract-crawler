// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out of the darkness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Maybe something maybe nothing…    //
//                                      //
//                                      //
//////////////////////////////////////////


contract APAX2 is ERC1155Creator {
    constructor() ERC1155Creator("Out of the darkness", "APAX2") {}
}