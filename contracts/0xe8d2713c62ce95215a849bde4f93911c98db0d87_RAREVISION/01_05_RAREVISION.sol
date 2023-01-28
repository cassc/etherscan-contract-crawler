// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RARE VISION COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    RARE VISION COLLECTION    //
//                              //
//                              //
//////////////////////////////////


contract RAREVISION is ERC1155Creator {
    constructor() ERC1155Creator("RARE VISION COLLECTION", "RAREVISION") {}
}