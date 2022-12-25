// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy X‘mas Stranger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//    Merry x‘mas!!🎈 can you let me in please it‘s very cold outside :)    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract XMS is ERC721Creator {
    constructor() ERC721Creator(unicode"Happy X‘mas Stranger", "XMS") {}
}