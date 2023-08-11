// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AstroOTTO The Green Star
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    //////////////////////////////    //
//                                      //
//    AstroOTTO The Green Star cover    //
//                                      //
//    //////////////////////////////    //
//                                      //
//                                      //
//////////////////////////////////////////


contract AOGS is ERC1155Creator {
    constructor() ERC1155Creator("AstroOTTO The Green Star", "AOGS") {}
}