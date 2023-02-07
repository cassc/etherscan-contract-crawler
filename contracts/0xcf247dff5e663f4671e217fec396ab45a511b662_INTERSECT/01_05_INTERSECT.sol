// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INTERSECT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//    I'm an artist from Thailand. i love art I'm happy to create works.    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract INTERSECT is ERC1155Creator {
    constructor() ERC1155Creator("INTERSECT", "INTERSECT") {}
}