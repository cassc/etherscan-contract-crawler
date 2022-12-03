// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRIBIT RINGS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    FRIBIT RINGS: Digital wedding rings uniquely designed for your metaverse wedding    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FRIBITRINGS is ERC1155Creator {
    constructor() ERC1155Creator("FRIBIT RINGS", "FRIBITRINGS") {}
}